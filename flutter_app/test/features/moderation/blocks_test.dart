import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:esel/features/auth/data/sources/auth_mock_source.dart';
import 'package:esel/features/auth/data/sources/auth_remote_source.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/features/auth/presentation/controllers/auth_controller.dart';
import 'package:esel/features/moderation/data/blocks_source.dart';
import 'package:esel/features/moderation/domain/blocked_user.dart';
import 'package:esel/features/moderation/presentation/controllers/blocks_controller.dart';
import 'package:esel/features/moderation/presentation/widgets/blocked_users_view.dart';
import 'package:esel/features/moderation/presentation/widgets/moderation_sheet.dart';
import 'package:esel/features/settings/presentation/screens/settings_screen.dart';
import '../server/core_api_widgets_test.dart' show ScreenHttp;

/// DEV-20 차단: 차단하기·풀기·차단 목록. 차단한 사람의 캔버스는 서버가 피드·팔레트·스케치북에서 뺀다.
void main() {
  test(
    '서버 소스: 차단은 POST, 풀기는 DELETE /users/:사인/block, 목록은 cursor로 GET /me/blocks',
    () async {
      final calls = <String>[];
      final http = ScreenHttp((method, path, body) async {
        calls.add('$method $path ${body ?? ''}');
        if (path == '/me/blocks') {
          return {
            'items': [
              {'masthead': 'elin', 'blockedAt': '2026-11-25T15:30:00.000Z'},
            ],
            'nextCursor': 'next',
          };
        }
        return {'masthead': 'elin', 'blocked': method == 'POST'};
      });
      final source = BlocksRemoteSource(http);
      await source.block('elin');
      await source.unblock('elin');
      final page = await source.page();
      await source.page(cursor: 'next');
      expect(page.items.single.masthead, 'elin');
      expect(page.nextCursor, 'next');
      expect(calls, [
        'POST /users/elin/block ',
        'DELETE /users/elin/block ',
        'GET /me/blocks {}',
        'GET /me/blocks {cursor: next}',
      ]);
    },
  );

  group('차단 상태', () {
    test('차단은 서버가 답한 뒤에만 목록에 넣고, 성공했을 때만 홈·팔레트를 다시 읽게 한다', () async {
      final source = _FakeBlocks();
      var changed = 0;
      final controller = BlocksController(source, onChanged: () => changed++);
      final pending = Completer<void>();
      source.blockResult = pending.future;
      final done = controller.block('elin');
      expect(controller.isBusy('elin'), isTrue);
      expect(controller.items, isEmpty);
      expect(changed, 0);
      pending.complete();
      expect(await done, isNull);
      expect(controller.items.map((b) => b.masthead), ['elin']);
      expect(changed, 1);
    });

    test('실패하면 안내하고 목록·화면을 바꾸지 않는다', () async {
      final source = _FakeBlocks()
        ..blockError = const NotFoundFailure('찾을 수 없어요.', code: 'NOT_FOUND');
      var changed = 0;
      final controller = BlocksController(source, onChanged: () => changed++);
      expect(await controller.block('nobody'), '찾을 수 없는 사람이에요.');
      expect(controller.items, isEmpty);
      expect(changed, 0);
    });

    test('풀기는 서버가 답한 뒤 목록에서 빼고 다시 읽게 한다', () async {
      final source = _FakeBlocks()
        ..items = [const BlockedUser(masthead: 'elin')];
      var changed = 0;
      final controller = BlocksController(source, onChanged: () => changed++);
      await controller.load();
      expect(await controller.unblock('elin'), isNull);
      expect(controller.items, isEmpty);
      expect(changed, 1);
      expect(source.unblocked, ['elin']);
    });

    test('계정이 바뀌면 이전 계정의 늦은 목록을 버린다', () async {
      final source = _FakeBlocks();
      final slow = Completer<BlockedUsersPage>();
      source.pageResult = slow.future;
      final controller = BlocksController(source)..configure('user-a');
      final loading = controller.load();
      controller.configure('user-b');
      slow.complete(const BlockedUsersPage([BlockedUser(masthead: 'old')]));
      await loading;
      expect(controller.items, isEmpty);
      expect(controller.hasLoaded, isFalse);
    });
  });

  group('차단 시트', () {
    Future<void> openSheet(WidgetTester tester, {VoidCallback? onBlock}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => ModerationSheet.show(
                context,
                authorMasthead: 'elin',
                onReport: () {},
                onBlock: onBlock,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('내 캔버스처럼 차단할 수 없으면 차단 항목이 없다', (tester) async {
      await openSheet(tester);
      expect(find.byKey(const Key('moderation-block')), findsNothing);
    });

    testWidgets('차단을 누르면 시트를 닫고 부른다. 차단됐다는 안내는 시트가 미리 띄우지 않는다', (tester) async {
      var blocked = 0;
      await openSheet(tester, onBlock: () => blocked++);
      await tester.tap(find.byKey(const Key('moderation-block')));
      await tester.pumpAndSettle();
      expect(blocked, 1);
      expect(find.byKey(const Key('moderation-block')), findsNothing);
      expect(find.textContaining('차단했'), findsNothing);
    });
  });

  group('설정 > 차단한 사람', () {
    Future<void> pumpView(
      WidgetTester tester,
      BlocksController controller, {
      bool demo = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockedUsersView(controller: controller, demo: demo),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('목록을 숫자 없이 보이고, 풀기는 서버가 답한 뒤 빼며 안내한다', (tester) async {
      final source = _FakeBlocks()
        ..items = [
          BlockedUser(
            masthead: 'elin',
            blockedAt: DateTime.utc(2026, 11, 25, 15, 30),
          ),
        ];
      final pending = Completer<void>();
      source.unblockResult = pending.future;
      await pumpView(tester, BlocksController(source));
      expect(find.byKey(const Key('blocks-user-elin')), findsOneWidget);
      // 서울 날짜(UTC 15:30 → 다음 날 00:30).
      expect(find.text('2026. 11. 26. 차단'), findsOneWidget);

      await tester.tap(find.byKey(const Key('blocks-unblock-elin')));
      await tester.pump();
      final button = tester.widget<TextButton>(
        find.byKey(const Key('blocks-unblock-elin')),
      );
      expect(button.onPressed, isNull);

      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('blocks-user-elin')), findsNothing);
      expect(find.byKey(const Key('blocks-empty')), findsOneWidget);
      expect(find.text('elin 님의 차단을 풀었어요.'), findsOneWidget);
    });

    testWidgets('불러오기 실패는 다시 시도, mock 모드는 화면을 거르지 않는다고 안내한다', (tester) async {
      final source = _FakeBlocks()
        ..pageError = const NetworkFailure('인터넷 연결을 확인해 주세요.', code: 'OFFLINE');
      await pumpView(tester, BlocksController(source), demo: true);
      expect(find.text('인터넷 연결을 확인해 주세요.'), findsOneWidget);
      source.pageError = null;
      await tester.tap(find.byKey(const Key('blocks-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('blocks-empty')), findsOneWidget);
      expect(find.textContaining('시연 모드'), findsOneWidget);
    });

    testWidgets('설정 메뉴에 차단한 사람이 있고 누르면 목록이 열린다', (tester) async {
      const config = AppConfig(apiMode: ApiMode.mock);
      final storage = InMemorySessionStorage();
      final auth = AuthController(
        AuthRepositoryImpl(
          config: config,
          storage: storage,
          mockSource: AuthMockSource(
            accounts: MockAccountStore(InMemoryMockAccountVault()),
          ),
          remoteSource: AuthRemoteSource(
            StandardHttpClient(config: config, storage: storage),
          ),
        ),
      );
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            authController: auth,
            blocks: BlocksController(_FakeBlocks()),
            onBack: () {},
            onLogoutComplete: () {},
            onDeleteComplete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('차단한 사람'));
      await tester.pumpAndSettle();
      expect(find.byType(BlockedUsersView), findsOneWidget);
      expect(find.byKey(const Key('blocks-empty')), findsOneWidget);
    });
  });
}

class _FakeBlocks implements BlocksSource {
  List<BlockedUser> items = [];
  Future<void>? blockResult, unblockResult;
  Future<BlockedUsersPage>? pageResult;
  // 오류는 부를 때 던진다. 미리 만든 오류 Future는 처리 안 된 오류가 된다.
  Failure? blockError, pageError;
  final unblocked = <String>[];

  @override
  Future<void> block(String masthead) async {
    if (blockError != null) throw blockError!;
    await blockResult;
  }

  @override
  Future<void> unblock(String masthead) async {
    await unblockResult;
    unblocked.add(masthead);
  }

  @override
  Future<BlockedUsersPage> page({String? cursor}) async {
    if (pageError != null) throw pageError!;
    return pageResult ?? BlockedUsersPage(items);
  }
}
