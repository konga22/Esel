import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/media/domain/models/face_layout_mode.dart';
import 'package:esel/features/media/presentation/face_adjust_guide.dart';

void main() {
  group('얼굴 위치 안내(PR #21 리뷰 후속)', () {
    var toggled = 0;
    Future<void> pump(
      WidgetTester tester, {
      Set<FaceLayoutMode> effects = const {FaceLayoutMode.original},
      bool locating = false,
      bool placed = true,
      bool directTap = false,
      bool cancelHere = true,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FaceAdjustGuide(
            effects: effects,
            locating: locating,
            placed: placed,
            directTap: directTap,
            cancelHere: cancelHere,
            onToggle: () => toggled++,
          ),
        ),
      ),
    );

    testWidgets('물감이 켜져 있으면 물감 위치 옮기기, 누르면 위치 지정 시작', (tester) async {
      toggled = 0;
      await pump(tester, effects: {FaceLayoutMode.paintStroke});
      expect(find.text('물감 위치가 어긋났나요?'), findsOneWidget);
      expect(find.textContaining('얼굴 가운데를 누르면 물감이 그 자리로'), findsOneWidget);
      await tester.tap(find.text('물감 위치 옮기기'));
      expect(toggled, 1);
      // 버튼은 엄지로 누를 수 있는 크기.
      expect(
        tester.getSize(find.byKey(const Key('face-adjust-action'))).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('사인 뒤로 + 물감도 물감 안내', (tester) async {
      await pump(
        tester,
        effects: {FaceLayoutMode.behindLogo, FaceLayoutMode.paintStroke},
      );
      expect(find.text('물감 위치 옮기기'), findsOneWidget);
    });

    testWidgets('목 아래는 물감 대신 자른 자리 안내(P15)', (tester) async {
      await pump(tester, effects: {FaceLayoutMode.belowNeck});
      expect(find.text('목 아래 · 물감은 쓰지 않아요'), findsOneWidget);
      expect(find.text('얼굴 위치 다시 정하기'), findsOneWidget);
      expect(find.text('물감 위치 옮기기'), findsNothing);
    });

    testWidgets('아직 위치를 안 정했으면 얼굴 위치 맞추기', (tester) async {
      await pump(tester, effects: {FaceLayoutMode.paintStroke}, placed: false);
      expect(find.text('얼굴 위치를 정해 주세요'), findsOneWidget);
      expect(find.text('얼굴 위치 맞추기'), findsOneWidget);
    });

    testWidgets('위치 지정 중: 원본이라는 설명, 취소는 둘 곳에만', (tester) async {
      await pump(tester, locating: true);
      expect(find.text('사진에서 얼굴 가운데를 눌러 주세요'), findsOneWidget);
      expect(find.text('효과 미리보기로 돌아가기'), findsOneWidget);
      await pump(tester, locating: true, cancelHere: false);
      expect(find.byKey(const Key('face-adjust-action')), findsNothing);
    });

    testWidgets('편집기에서 확인 전이면 표지를 바로 눌러도 된다고 알려 준다', (tester) async {
      await pump(
        tester,
        effects: {FaceLayoutMode.paintStroke},
        directTap: true,
      );
      expect(find.textContaining('표지를 바로 누르거나 끌어도 돼요'), findsOneWidget);
      await pump(tester, effects: {FaceLayoutMode.paintStroke});
      expect(find.textContaining('표지를 바로 누르거나 끌어도 돼요'), findsNothing);
    });
  });
}
