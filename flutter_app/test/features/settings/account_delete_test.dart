import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/core/ui/esel_button.dart';
import 'package:esel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:esel/features/auth/data/sources/auth_mock_source.dart';
import 'package:esel/features/auth/data/sources/auth_remote_source.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/features/auth/presentation/controllers/auth_controller.dart';
import 'package:esel/features/settings/presentation/screens/settings_screen.dart';
import '../server/core_api_widgets_test.dart' show ScreenHttp;

/// DEV-19 탈퇴 화면(S4·S6). 2026-11-23 실서버 확인에서 찾은 두 문제를 고정한다.
/// 1) 서버 실패 시 안내 없이 대화상자만 닫히고 처리되지 않은 오류가 남던 문제
/// 2) 확인 체크 전 "탈퇴 진행하기"가 비활성으로 보이지 않던 문제
void main() {
  test('서버가 실패하면 탈퇴는 오류를 그대로 알리고, 로딩을 풀고, 로그인을 유지한다', () async {
    final storage = InMemorySessionStorage();
    final http = ScreenHttp((method, path, _) async {
      if (path == '/auth/email/login') {
        return {
          'userId': 'user-id',
          'email': 'me@example.test',
          'masthead': 'selin',
          'hasPublishedToday': false,
          'issueCount': 0,
          'accessToken': 'access',
          'refreshToken': 'refresh',
        };
      }
      expect('$method $path', 'DELETE /me');
      throw const NetworkFailure('서버에 연결할 수 없어요.', code: 'OFFLINE');
    });
    final controller = AuthController(
      AuthRepositoryImpl(
        config: const AppConfig(apiBaseUrl: 'http://127.0.0.1:9/api'),
        storage: storage,
        mockSource: AuthMockSource(),
        remoteSource: AuthRemoteSource(http),
      ),
    );
    addTearDown(controller.dispose);
    expect(
      await controller.loginWithEmail('me@example.test', 'correct password'),
      isTrue,
    );

    await expectLater(
      controller.deleteAccount(),
      throwsA(isA<NetworkFailure>()),
    );
    expect(controller.isLoading, isFalse);
    expect(controller.currentSession?.userId, 'user-id');
    expect(await storage.getTokens(), isNotNull);
  });

  group('설정 화면 · 계정 관리(S4) · 탈퇴(S6)', () {
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

    Future<void> openAccount(
      WidgetTester tester, {
      required Future<void> Function() deleteAccount,
      required VoidCallback onDeleteComplete,
    }) async {
      final controller = auth();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            authController: controller,
            deleteAccount: deleteAccount,
            onBack: () {},
            onLogoutComplete: () {},
            onDeleteComplete: onDeleteComplete,
          ),
        ),
      );
      await tester.tap(find.text('계정 관리'));
      await tester.pumpAndSettle();
    }

    EselButton deleteButton(WidgetTester tester) =>
        tester.widget<EselButton>(find.widgetWithText(EselButton, '탈퇴 진행하기'));

    Future<void> confirmDelete(WidgetTester tester) async {
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.widgetWithText(EselButton, '탈퇴 진행하기'));
      await tester.pumpAndSettle();
      expect(find.text('계정 삭제 최종 확인'), findsOneWidget);
      await tester.tap(find.text('영구 삭제'));
    }

    testWidgets('확인 체크 전에는 탈퇴 진행하기가 비활성으로 보이고 눌러도 다음 단계가 열리지 않는다', (
      tester,
    ) async {
      await openAccount(
        tester,
        deleteAccount: () async {},
        onDeleteComplete: () {},
      );
      expect(deleteButton(tester).enabled, isFalse);
      await tester.tap(
        find.widgetWithText(EselButton, '탈퇴 진행하기'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('계정 삭제 최종 확인'), findsNothing);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(deleteButton(tester).enabled, isTrue);
    });

    testWidgets('탈퇴가 실패하면 이유를 알리고 계정 관리에 머문다(처리되지 않은 오류 없음)', (tester) async {
      var completed = 0;
      await openAccount(
        tester,
        deleteAccount: () async =>
            throw const NetworkFailure('서버에 연결할 수 없어요. 연결을 확인하고 다시 시도해 주세요.'),
        onDeleteComplete: () => completed++,
      );
      await confirmDelete(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(completed, 0);
      expect(find.text('서버에 연결할 수 없어요. 연결을 확인하고 다시 시도해 주세요.'), findsOneWidget);
      expect(find.text('계정 관리'), findsOneWidget);
      // 다시 시도할 수 있다.
      expect(deleteButton(tester).enabled, isTrue);
    });

    testWidgets('탈퇴하는 동안 버튼을 막고, 성공하면 한 번만 완료 처리한다', (tester) async {
      final gate = Completer<void>();
      var calls = 0, completed = 0;
      await openAccount(
        tester,
        deleteAccount: () async {
          calls++;
          await gate.future;
        },
        onDeleteComplete: () => completed++,
      );
      await confirmDelete(tester);
      await tester.pump();
      expect(
        tester
            .widget<EselButton>(find.widgetWithText(EselButton, '탈퇴하는 중…'))
            .enabled,
        isFalse,
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      gate.complete();
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(completed, 1);
    });
  });
}
