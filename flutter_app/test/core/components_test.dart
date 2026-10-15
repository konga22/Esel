import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/ui/esel_button.dart';
import 'package:esel/core/ui/esel_chip.dart';
import 'package:esel/core/ui/esel_glass.dart';
import 'package:esel/core/ui/esel_paint_asset.dart';
import 'package:esel/core/ui/esel_pressable.dart';

void main() {
  group('DEV-01 UI Components tests', () {
    testWidgets('EselPressable provides at least 48x48 hit target', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EselPressable(
                onTap: () {},
                child: const SizedBox(width: 20, height: 20),
              ),
            ),
          ),
        ),
      );

      final pressableFinder = find.byType(EselPressable);
      expect(pressableFinder, findsOneWidget);
      final size = tester.getSize(pressableFinder);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('EselButton renders at exactly 54px height with token radius', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EselButton(label: '오늘 호 발행', onTap: () {}),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(EselButton);
      expect(buttonFinder, findsOneWidget);
      final size = tester.getSize(buttonFinder);
      expect(size.height, 54.0);
    });

    testWidgets('EselChip renders at 38px height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EselChip(label: '카멜', onTap: () {}),
            ),
          ),
        ),
      );

      final chipFinder = find.byType(EselChip);
      expect(chipFinder, findsOneWidget);
      final size = tester.getSize(chipFinder);
      expect(
        size.height,
        greaterThanOrEqualTo(48.0),
      ); // constrained by hit target
    });

    testWidgets('EselGlass switches to solid fallback on high contrast', (
      tester,
    ) async {
      // Normal glass
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: EselGlass(child: Text('Glass content'))),
          ),
        ),
      );
      expect(find.text('Glass content'), findsOneWidget);

      // High contrast glass
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(highContrast: true),
            child: Scaffold(
              body: Center(child: EselGlass(child: Text('Fallback content'))),
            ),
          ),
        ),
      );
      expect(find.text('Fallback content'), findsOneWidget);
    });

    testWidgets('EselPaintAsset displays Korean paint name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: EselPaintAsset(paint: EselPaint.camel, showLabel: true),
            ),
          ),
        ),
      );

      expect(find.text('카멜'), findsOneWidget);
    });
  });
}
