import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/ui/esel_phone_frame.dart';

void main() {
  Widget app() => MaterialApp(
    builder: (context, child) => EselPhoneFrame(child: child!),
    home: const Scaffold(body: SizedBox.expand()),
  );

  testWidgets('wide windows keep the phone-width design centered', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());

    final scaffold = find.byType(Scaffold);
    expect(tester.getSize(scaffold), const Size(430, 720));
    expect(tester.getCenter(scaffold), const Offset(640, 360));
    final context = tester.element(scaffold);
    expect(MediaQuery.sizeOf(context), const Size(430, 720));
  });

  testWidgets('phones use the full screen as before', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());

    expect(tester.getSize(find.byType(Scaffold)), const Size(393, 852));
  });
}
