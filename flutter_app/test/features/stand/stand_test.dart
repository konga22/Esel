import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/stand/presentation/controllers/stand_controller.dart';
import 'package:esel/features/stand/presentation/screens/stand_screen.dart';

void main() {
  group('DEV-12 StandScreen Tests (P01)', () {
    testWidgets('renders stand chips and locked preview room before publishing', (tester) async {
      final controller = StandController();
      controller.selectColor('powder-blue');

      await tester.pumpWidget(
        MaterialApp(
          home: StandScreen(
            controller: controller,
            mySelectedColorKey: 'powder-blue',
            hasPublishedToday: false,
            onSelectCover: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('가판대'), findsOneWidget);
      expect(find.text('발행하면 함께 펼쳐집니다'), findsOneWidget);
    });
  });
}
