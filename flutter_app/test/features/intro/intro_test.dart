import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/intro/presentation/screens/intro_screen.dart';

void main() {
  group('DEV-04 IntroScreen Tests (P12, P16)', () {
    testWidgets('renders cover, scroll brings floating login bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IntroScreen(
            onOpenLogin: () {},
            onStartJoin: () {},
          ),
        ),
      );

      expect(find.text('Esel'), findsOneWidget);
      expect(find.text('dana'), findsOneWidget);

      // Scroll to trigger login bar
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();

      expect(find.text('로그인하고 계속 읽기'), findsOneWidget);
    });
  });
}
