import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/features/friends/data/friends_source.dart';
import 'package:esel/features/friends/domain/friend.dart';
import 'package:esel/features/friends/presentation/controllers/friends_controller.dart';
import 'package:esel/features/friends/presentation/screens/friends_screen.dart';
import '../server/core_api_widgets_test.dart' show ScreenHttp;

/// DEV-16 친구: 목록, 받은 요청 수락·나중에, 사인으로 찾기.
/// 합격 기준: 없는 아이디는 '찾지 못했어요'와 철자 확인 안내, 같은 요청 중복 생성 불가.
void main() {
  group('요청 전 규칙', () {
    test('사인 규칙(P14)·나 자신·이미 친구·이미 받은 요청은 서버에 보내기 전에 거른다', () {
      expect(friendRequestError(''), isNotNull);
      expect(friendRequestError('a'), contains('철자'));
      expect(friendRequestError('selin_01'), contains('철자'));
      expect(friendRequestError('selin', selfMasthead: 'selin'), isNotNull);
      expect(friendRequestError('elin', friends: ['elin']), '이미 친구예요.');
      expect(
        friendRequestError('kofi', received: ['kofi']),
        contains('받은 친구 요청에서 수락'),
      );
      expect(friendRequestError('dana'), isNull);
      expect(normalizeFriendMasthead('  Dana '), 'dana');
    });

    test('서버 오류 코드를 고칠 방법이 있는 한 줄로 바꾼다', () {
      expect(
        friendRequestFailureMessage(
          const NotFoundFailure('찾을 수 없어요.', code: 'NOT_FOUND'),
        ),
        '찾지 못했어요. 사인 철자를 확인해 주세요.',
      );
      expect(
        friendRequestFailureMessage(
          const RuleFailure('이미 보낸 요청이 있어요.', code: 'REQUEST_EXISTS'),
        ),
        contains('이미 요청이 있어요'),
      );
      expect(
        friendRequestFailureMessage(
          const RuleFailure('이미 친구예요.', code: 'ALREADY_FRIENDS'),
        ),
        '이미 친구예요.',
      );
      expect(
        friendRequestActionFailureMessage(
          const NotFoundFailure('찾을 수 없어요.', code: 'NOT_FOUND'),
        ),
        contains('이미 처리'),
      );
    });
  });

  group('서버 소스(api-contract friends)', () {
    test('목록·요청은 cursor로 읽고, 보내기는 사인만, 수락·나중에는 요청 ID 경로로 부른다', () async {
      final calls = <String>[];
      final http = ScreenHttp((method, path, body) async {
        calls.add('$method $path ${body ?? ''}');
        switch ('$method $path') {
          case 'GET /friends':
            return {
              'items': [
                {
                  'friendId': 'u-elin',
                  'masthead': 'elin',
                  'friendsSince': '2026-11-20T03:00:00.000Z',
                },
              ],
              'nextCursor': 'c2',
            };
          case 'GET /friends/requests':
            return {
              'items': [
                {
                  'id': 'r-1',
                  'masthead': 'kofi',
                  'createdAt': '2026-11-25T00:00:00.000Z',
                },
              ],
              'nextCursor': null,
            };
          case 'POST /friends/requests/r-1/accept':
            return {
              'friendId': 'u-kofi',
              'masthead': 'kofi',
              'friendsSince': '2026-11-26T00:00:00.000Z',
            };
        }
        return {};
      });
      final source = FriendsRemoteSource(http);

      final friends = await source.friends();
      expect(friends.items.single.id, 'u-elin');
      expect(friends.items.single.masthead, 'elin');
      expect(friends.items.single.bio, isNull);
      expect(friends.items.single.photoAsset, isNull);
      expect(friends.nextCursor, 'c2');
      await source.friends(cursor: 'c2');

      final requests = await source.requests();
      expect(requests.items.single.fromMasthead, 'kofi');
      expect(requests.nextCursor, isNull);

      await source.sendRequest('dana');
      final accepted = await source.accept(requests.items.single);
      expect(accepted.id, 'u-kofi');
      await source.decline('r-2');

      expect(calls, [
        'GET /friends {}',
        'GET /friends {cursor: c2}',
        'GET /friends/requests {}',
        'POST /friends/requests {masthead: dana}',
        'POST /friends/requests/r-1/accept ',
        'POST /friends/requests/r-2/decline ',
      ]);
    });
  });

  group('친구 상태', () {
    test('수락은 서버가 답한 뒤에만 친구로 옮긴다', () async {
      final source = _FakeSource();
      final controller = FriendsController(source);
      await controller.load();
      expect(controller.pendingRequests.map((r) => r.fromMasthead), ['kofi']);

      final pending = Completer<FriendItem>();
      source.acceptResult = pending.future;
      final done = controller.acceptRequest(controller.pendingRequests.single);
      expect(controller.isBusy('r-1'), isTrue);
      expect(controller.friends.map((f) => f.masthead), ['elin']);

      pending.complete(const FriendItem(id: 'u-kofi', masthead: 'kofi'));
      expect(await done, isNull);
      expect(controller.friends.map((f) => f.masthead), ['kofi', 'elin']);
      expect(controller.pendingRequests, isEmpty);
      expect(controller.isBusy('r-1'), isFalse);
      expect(controller.knownFriendCount, 2);
    });

    test('이미 처리된 요청(404)은 안내하고 목록에서 뺀다', () async {
      final source = _FakeSource()
        ..acceptError = const NotFoundFailure('찾을 수 없어요.', code: 'NOT_FOUND');
      final controller = FriendsController(source);
      await controller.load();
      final message = await controller.acceptRequest(
        controller.pendingRequests.single,
      );
      expect(message, contains('이미 처리'));
      expect(controller.pendingRequests, isEmpty);
      expect(controller.friends.map((f) => f.masthead), ['elin']);
    });

    test('같은 요청 중복: 이미 받은 요청은 서버에 보내지 않고, 서버의 409는 안내로 바꾼다', () async {
      final source = _FakeSource();
      final controller = FriendsController(source);
      await controller.load();

      expect(
        await controller.sendRequest('kofi', selfMasthead: 'selin'),
        contains('받은 친구 요청에서 수락'),
      );
      expect(await controller.sendRequest('Elin'), '이미 친구예요.');
      expect(source.sent, isEmpty);

      source.sendError = const RuleFailure(
        '이미 보낸 요청이 있어요.',
        code: 'REQUEST_EXISTS',
      );
      expect(await controller.sendRequest('dana'), contains('이미 요청이 있어요'));
      expect(source.sent, ['dana']);
    });

    test('다음 페이지가 남으면 전체 수를 모른다(null)', () async {
      final source = _FakeSource()..friendsCursor = 'next';
      final controller = FriendsController(source);
      await controller.load();
      expect(controller.knownFriendCount, isNull);
      expect(controller.hasMoreFriends, isTrue);
    });

    test('계정이 바뀌면 이전 계정의 늦은 응답을 버린다', () async {
      final source = _FakeSource();
      final slow = Completer<FriendsPage<FriendItem>>();
      source.friendsResult = slow.future;
      final controller = FriendsController(source)..configure('user-a');
      final loading = controller.load();
      controller.configure('user-b');
      slow.complete(
        const FriendsPage([FriendItem(id: 'u-old', masthead: 'old')]),
      );
      await loading;
      expect(controller.friends, isEmpty);
      expect(controller.hasLoaded, isFalse);
    });
  });

  group('친구 화면(F1~F3)', () {
    Future<_FakeSource> pump(
      WidgetTester tester, {
      _FakeSource? source,
      VoidCallback? onOpenTwin,
    }) async {
      final s = source ?? _FakeSource();
      await tester.pumpWidget(
        MaterialApp(
          home: FriendsScreen(
            controller: FriendsController(s),
            onBack: () {},
            onOpenTwin: onOpenTwin,
            selfMasthead: 'selin',
          ),
        ),
      );
      return s;
    }

    testWidgets('열면 서버 목록을 읽고, 사진 없는 사람은 사인 첫 글자와 친구가 된 날로 보인다', (
      tester,
    ) async {
      await pump(tester);
      await tester.pumpAndSettle();
      expect(find.text('받은 친구 요청 (1)'), findsOneWidget);
      expect(find.text('나의 친구 (1)'), findsOneWidget);
      expect(find.byKey(const Key('friends-friend-elin')), findsOneWidget);
      expect(find.text('2026. 11. 20.부터 친구'), findsOneWidget);
      // 트윈이 연결되지 않은 서버 모드에서는 트윈 줄이 없다.
      expect(find.byKey(const Key('friends-twin')), findsNothing);
    });

    testWidgets('친구가 없으면 빈 화면 안내, 불러오기 실패는 다시 시도', (tester) async {
      final source = _FakeSource()
        ..friendItems = []
        ..requestItems = []
        ..friendsError = const NetworkFailure(
          '인터넷 연결을 확인해 주세요.',
          code: 'OFFLINE',
        );
      await pump(tester, source: source);
      await tester.pumpAndSettle();
      expect(find.text('인터넷 연결을 확인해 주세요.'), findsOneWidget);

      source.friendsError = null;
      await tester.tap(find.byKey(const Key('friends-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('friends-empty')), findsOneWidget);
      expect(find.text('나의 친구 (0)'), findsOneWidget);
    });

    testWidgets("없는 사인은 시트를 닫지 않고 '찾지 못했어요'와 철자 확인을 안내한다", (tester) async {
      final source = _FakeSource()
        ..sendError = const NotFoundFailure('찾을 수 없어요.', code: 'NOT_FOUND');
      await pump(tester, source: source);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('friends-add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('friends-add-input')),
        'nobody',
      );
      await tester.tap(find.byKey(const Key('friends-add-send')));
      await tester.pumpAndSettle();
      expect(find.text('찾지 못했어요. 사인 철자를 확인해 주세요.'), findsOneWidget);
      expect(find.byKey(const Key('friends-add-input')), findsOneWidget);

      source.sendError = null;
      await tester.enterText(
        find.byKey(const Key('friends-add-input')),
        'Dana ',
      );
      await tester.tap(find.byKey(const Key('friends-add-send')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('friends-add-input')), findsNothing);
      expect(find.text('dana 님에게 친구 요청을 보냈어요.'), findsOneWidget);
      expect(source.sent, ['nobody', 'dana']);
    });

    testWidgets('수락 중에는 버튼을 막고, 끝나면 친구 목록으로 옮긴다', (tester) async {
      final source = _FakeSource();
      final pending = Completer<FriendItem>();
      source.acceptResult = pending.future;
      await pump(tester, source: source);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('friends-accept-r-1')));
      await tester.pump();
      final accept = tester.widget<TextButton>(
        find.byKey(const Key('friends-accept-r-1')),
      );
      expect(accept.onPressed, isNull);

      pending.complete(const FriendItem(id: 'u-kofi', masthead: 'kofi'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('friends-request-r-1')), findsNothing);
      expect(find.byKey(const Key('friends-friend-kofi')), findsOneWidget);
      expect(find.text('kofi 님과 친구가 되었어요.'), findsOneWidget);
    });

    testWidgets('mock 모드는 트윈 줄을 그대로 보인다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendsScreen(
            controller: FriendsController(FriendsMockSource()),
            onBack: () {},
            onOpenTwin: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('friends-twin')), findsOneWidget);
      expect(find.byKey(const Key('friends-friend-elin')), findsOneWidget);
      expect(find.byKey(const Key('friends-request-req_1')), findsOneWidget);
    });
  });
}

class _FakeSource implements FriendsSource {
  List<FriendItem> friendItems = [
    FriendItem(
      id: 'u-elin',
      masthead: 'elin',
      friendsSince: DateTime.utc(2026, 11, 20, 3),
    ),
  ];
  List<FriendRequestItem> requestItems = const [
    FriendRequestItem(id: 'r-1', fromMasthead: 'kofi'),
  ];
  String? friendsCursor;
  Future<FriendsPage<FriendItem>>? friendsResult;
  Future<FriendItem>? acceptResult;
  // 오류는 부를 때 던진다. 미리 만든 오류 Future는 아무도 기다리기 전에 처리 안 된 오류가 된다.
  Failure? friendsError, acceptError, sendError;
  final sent = <String>[];

  @override
  Future<FriendsPage<FriendItem>> friends({String? cursor}) async {
    if (friendsError != null) throw friendsError!;
    return friendsResult ?? FriendsPage(friendItems, friendsCursor);
  }

  @override
  Future<FriendsPage<FriendRequestItem>> requests({String? cursor}) async =>
      FriendsPage(requestItems);

  @override
  Future<void> sendRequest(String masthead) async {
    sent.add(masthead);
    if (sendError != null) throw sendError!;
  }

  @override
  Future<FriendItem> accept(FriendRequestItem request) async {
    if (acceptError != null) throw acceptError!;
    return acceptResult ??
        FriendItem(
          id: 'u-${request.fromMasthead}',
          masthead: request.fromMasthead,
        );
  }

  @override
  Future<void> decline(String requestId) async {}
}
