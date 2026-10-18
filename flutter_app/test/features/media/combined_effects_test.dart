import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/ui/esel_paint_asset.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/media/domain/models/face_layout_mode.dart';
import 'package:esel/features/media/presentation/cover_photo.dart';
import 'package:esel/features/media/presentation/cover_preview.dart';
import 'package:esel/features/onboarding/presentation/controllers/onboarding_controller.dart';

void main() {
  test('자르기는 단일 선택, 물감은 독립 토글이며 목 아래에서는 차단한다', () {
    final c = OnboardingController();
    c.selectFaceMode(FaceLayoutMode.paintStroke);
    c.selectFaceMode(FaceLayoutMode.behindLogo);
    expect(c.draft.effectiveFaceEffects, {
      FaceLayoutMode.behindLogo,
      FaceLayoutMode.paintStroke,
    });
    c.selectFaceMode(FaceLayoutMode.behindLogo);
    expect(c.draft.effectiveFaceEffects, hasLength(2));
    c.selectFaceMode(FaceLayoutMode.original);
    expect(c.draft.effectiveFaceEffects, {FaceLayoutMode.paintStroke});
    c.selectFaceMode(FaceLayoutMode.paintStroke);
    expect(c.draft.effectiveFaceEffects, isEmpty);
    c.selectFaceMode(FaceLayoutMode.paintStroke);
    c.selectFaceMode(FaceLayoutMode.belowNeck);
    expect(c.draft.effectiveFaceEffects, {FaceLayoutMode.belowNeck});
    c.selectFaceMode(FaceLayoutMode.paintStroke);
    expect(c.draft.effectiveFaceEffects, {FaceLayoutMode.belowNeck});
    c.selectFaceMode(FaceLayoutMode.original);
    expect(c.draft.effectiveFaceEffects, isEmpty);
    c.selectFaceMode(FaceLayoutMode.behindLogo);
    expect(c.draft.effectiveFaceEffects, {FaceLayoutMode.behindLogo});
  });

  test('모든 이전 조합과 버튼 전환에서 단일 자르기 및 목 아래 물감 금지를 유지한다', () {
    final values = FaceLayoutMode.values;
    for (var bits = 0; bits < 1 << values.length; bits++) {
      final legacy = {
        for (var i = 0; i < values.length; i++)
          if (bits & (1 << i) != 0) values[i],
      };
      for (final mode in values) {
        final next = toggleFaceEffect(legacy, mode);
        expect(next.contains(FaceLayoutMode.original), isFalse);
        expect(
          next.where((v) => v != FaceLayoutMode.paintStroke).length,
          lessThanOrEqualTo(1),
        );
        if (next.contains(FaceLayoutMode.belowNeck)) {
          expect(next, {FaceLayoutMode.belowNeck});
        }
        final roundTrip = CoverDraft.fromJson(
          CoverDraft(
            id: 'legacy',
            photoPath: 'photo',
            faceEffects: next,
            faceWidth: .27,
            mastheadScale: 1.2,
            updatedAt: DateTime(2026),
          ).toJson(),
        );
        expect(roundTrip.effectiveFaceEffects, next);
        expect(roundTrip.faceWidth, .27);
        expect(roundTrip.mastheadScale, 1.2);
      }
    }
  });

  test('이전 단일 효과 저장본과 새 다중 효과·사인 크기 저장본을 모두 읽는다', () {
    final old =
        CoverDraft(
            id: 'old',
            photoPath: 'p',
            faceMode: FaceLayoutMode.paintStroke,
            updatedAt: DateTime(2026),
          ).toJson()
          ..remove('faceEffects')
          ..remove('mastheadScale');
    final restored = CoverDraft.fromJson(old);
    expect(restored.effectiveFaceEffects, {FaceLayoutMode.paintStroke});
    expect(restored.mastheadScale, 1);
    final next = restored.copyWith(
      faceEffects: FaceLayoutMode.values.skip(1).toSet(),
      mastheadScale: 1.3,
    );
    final reloaded = CoverDraft.fromJson(next.toJson());
    expect(reloaded.effectiveFaceEffects, {FaceLayoutMode.belowNeck});
    expect(reloaded.mastheadScale, 1.3);
    expect(reloaded.faceMode, FaceLayoutMode.belowNeck);
    final reset = reloaded.copyWith(faceEffects: {});
    expect(reset.faceMode, FaceLayoutMode.original);
    expect(CoverDraft.fromJson(reset.toJson()).effectiveFaceEffects, isEmpty);
    expect(reloaded.copyWith(caption: 'keep').effectiveFaceEffects, {
      FaceLayoutMode.belowNeck,
    });
  });

  for (final crop in [FaceLayoutMode.behindLogo, FaceLayoutMode.belowNeck]) {
    testWidgets('물감 + $crop: P15에 맞는 레이어만 렌더링한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 400,
              child: CoverPreview(
                draft: CoverDraft(
                  id: 'd',
                  photoPath: 'missing.png',
                  masthead: 'look',
                  faceEffects: {FaceLayoutMode.paintStroke, crop},
                  mastheadScale: 1.3,
                  updatedAt: DateTime(2026),
                ),
              ),
            ),
          ),
        ),
      );
      final photo = find.byType(CoverPhoto);
      expect(tester.widget<CoverPhoto>(photo).mode, crop);
      expect(
        find.descendant(of: photo, matching: find.byType(EselPaintAsset)),
        crop == FaceLayoutMode.belowNeck ? findsNothing : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
