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
import 'package:esel/features/settings/data/notification_settings_source.dart';
import 'package:esel/features/settings/domain/notification_settings.dart';
import 'package:esel/features/settings/presentation/screens/settings_screen.dart';
import '../server/core_api_widgets_test.dart' show ScreenHttp;

/// DEV-19 알림 설정: GET/PUT /me/notifications. 실제 푸시 발송은 만들지 않는다(미정).
void main() {
  group('NotificationSettingsRemoteSource', () {
    test('GET은 세 값을 읽고 PUT은 세 값을 모두 보낸다', () async {
      final bodies = <Map<String, dynamic>?>[];
      final http = ScreenHttp((method, path, body) async {
        expect(path, '/me/notifications');
        if (method == 'GET') {
          return {'enabled': true, 'newIssue': true, 'reactions': false};
        }
        expect(method, 'PUT');
        bodies.add(body);
        return {...body!};
      });
      final source = NotificationSettingsRemoteSource(http);
      final loaded = await source.load();
      expect(loaded.enabled, isTrue);
      expect(loaded.newIssue, isTrue);
      expect(loaded.reactions, isFalse);

      final saved = await source.save(loaded.copyWith(enabled: false));
      // 전체를 꺼도 하위 값은 그대로 보낸다. 다시 켜면 이전 선택이 돌아온다.
      expect(bodies.single, {
        'enabled': false,
        'newIssue': true,
        'reactions': false,
      });
      expect(saved.enabled, isFalse);
    });

    test('서버 오류는 코드를 보존한다', () async {
      final source = NotificationSettingsRemoteSource(
        ScreenHttp(
          (_, _, _) async =>
              throw const RuleFailure('요청 형식을 확인해 주세요.', code: 'VALIDATION'),
        ),
      );
      await expectLater(
        source.save(const NotificationSettings.defaults()),
        throwsA(isA<RuleFailure>().having((e) => e.code, 'code', 'VALIDATION')),
      );
    });
  });

  group('설정 화면 · 알림 설정(S3, S3off)', () {
    AuthController auth() {
      const config = AppConfig(apiMode: ApiMode.mock);
      final storage = InMemorySessionStorage();
      return AuthController(
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
    }

    Future<void> openNotifications(
      WidgetTester tester,
      NotificationSettingsSource source,
    ) async {
      final controller = auth();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            authController: controller,
            notificationSettings: source,
            onBack: () {},
            onLogoutComplete: () {},
            onDeleteComplete: () {},
          ),
        ),
      );
      await tester.tap(find.text('알림 설정'));
      await tester.pump();
    }

    SwitchListTile tile(WidgetTester tester, String key) =>
        tester.widget<SwitchListTile>(find.byKey(ValueKey(key)));

    testWidgets('불러오는 동안 로딩을 보이고, 서버 값을 그대로 보인다', (tester) async {
      final gate = Completer<void>();
      final source = _FakeSource(
        onLoad: () async {
          await gate.future;
          return const NotificationSettings(
            enabled: true,
            newIssue: true,
            reactions: false,
          );
        },
      );
      await openNotifications(tester, source);
      expect(
        find.byKey(const ValueKey('notifications-loading')),
        findsOneWidget,
      );
      gate.complete();
      await tester.pumpAndSettle();
      expect(tile(tester, 'notify-enabled').value, isTrue);
      expect(tile(tester, 'notify-new-issue').value, isTrue);
      expect(tile(tester, 'notify-reactions').value, isFalse);
      // 알림 발송이 있는 것처럼 말하지 않는다.
      expect(find.textContaining('알림 발송은 아직 준비 중'), findsOneWidget);
      for (final key in ['notify-enabled', 'notify-new-issue']) {
        expect(
          tester.getSize(find.byKey(ValueKey(key))).height,
          greaterThanOrEqualTo(48),
        );
      }
    });

    testWidgets('전체를 끄면 하위 알림이 비활성되고, 서버에는 하위 값을 그대로 보낸다', (tester) async {
      final source = _FakeSource(
        onLoad: () async => const NotificationSettings.defaults(),
      );
      await openNotifications(tester, source);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('notify-enabled')));
      await tester.pumpAndSettle();
      expect(source.saved.single, {
        'enabled': false,
        'newIssue': true,
        'reactions': true,
      });
      expect(tile(tester, 'notify-enabled').value, isFalse);
      expect(tile(tester, 'notify-new-issue').onChanged, isNull);
      expect(tile(tester, 'notify-reactions').onChanged, isNull);
      expect(tile(tester, 'notify-new-issue').value, isFalse);
    });

    testWidgets('저장하는 동안 스위치를 막고, 서버가 답한 뒤에 바꾼다', (tester) async {
      final gate = Completer<void>();
      final source = _FakeSource(
        onLoad: () async => const NotificationSettings.defaults(),
        onSave: (next) async {
          await gate.future;
          return next;
        },
      );
      await openNotifications(tester, source);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('notify-reactions')));
      await tester.pump();
      // 서버 응답 전에는 성공으로 표시하지 않는다.
      expect(tile(tester, 'notify-reactions').value, isTrue);
      expect(tile(tester, 'notify-reactions').onChanged, isNull);
      expect(tile(tester, 'notify-enabled').onChanged, isNull);
      gate.complete();
      await tester.pumpAndSettle();
      expect(tile(tester, 'notify-reactions').value, isFalse);
      expect(tile(tester, 'notify-enabled').onChanged, isNotNull);
    });

    testWidgets('저장 실패는 이전 값을 유지하고 이유를 한 줄로 알린다', (tester) async {
      final source = _FakeSource(
        onLoad: () async => const NotificationSettings.defaults(),
        onSave: (_) async =>
            throw const NetworkFailure('서버에 연결하지 못했어요. 연결을 확인해 주세요.'),
      );
      await openNotifications(tester, source);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('notify-new-issue')));
      await tester.pumpAndSettle();
      expect(tile(tester, 'notify-new-issue').value, isTrue);
      expect(find.text('서버에 연결하지 못했어요. 연결을 확인해 주세요.'), findsOneWidget);
    });

    testWidgets('불러오기 실패는 이유와 다시 시도를 보이고, 실패한 동안 기본값을 지어내지 않는다', (
      tester,
    ) async {
      var fail = true;
      final source = _FakeSource(
        onLoad: () async {
          if (fail) {
            fail = false;
            throw const NetworkFailure('서버에 연결하지 못했어요.');
          }
          return const NotificationSettings(
            enabled: false,
            newIssue: true,
            reactions: true,
          );
        },
      );
      await openNotifications(tester, source);
      await tester.pumpAndSettle();
      expect(find.text('서버에 연결하지 못했어요.'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);
      await tester.tap(find.byKey(const ValueKey('notifications-retry')));
      await tester.pumpAndSettle();
      expect(tile(tester, 'notify-enabled').value, isFalse);
    });
  });
}

class _FakeSource implements NotificationSettingsSource {
  final Future<NotificationSettings> Function() onLoad;
  final Future<NotificationSettings> Function(NotificationSettings)? onSave;
  final saved = <Map<String, dynamic>>[];
  _FakeSource({required this.onLoad, this.onSave});

  @override
  Future<NotificationSettings> load() => onLoad();

  @override
  Future<NotificationSettings> save(NotificationSettings next) async {
    saved.add(next.toJson());
    return onSave == null ? next : onSave!(next);
  }
}
