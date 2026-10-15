import 'package:flutter_test/flutter_test.dart';
import 'package:esel/app/app.dart';
import 'package:esel/app/bootstrap/app_bootstrap.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/core/config/app_config.dart';
import 'dart:io';
import 'package:esel/features/drafts/data/local_library.dart';

void main() {
  testWidgets('EselApp smoke test verifies header and shell', (
    WidgetTester tester,
  ) async {
    AppConfig.current = const AppConfig(apiMode: ApiMode.mock);
    final directory = Directory.systemTemp.createTempSync('esel-app-test-');
    addTearDown(() => directory.deleteSync(recursive: true));
    await AppBootstrap.setup(
      localLibrary: LocalLibrary(directory),
      accountVault: InMemoryMockAccountVault(),
    );
    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();

    // Verify app title and issue number meta are present
    expect(find.text('Esel'), findsAtLeast(1));
    expect(find.text('dana'), findsOneWidget);
  });
}
