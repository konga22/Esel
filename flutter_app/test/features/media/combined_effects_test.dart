import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/ui/esel_paint_asset.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/media/domain/models/face_layout_mode.dart';
import 'package:esel/features/media/presentation/cover_photo.dart';
import 'package:esel/features/media/presentation/cover_preview.dart';
import 'package:esel/features/onboarding/presentation/controllers/onboarding_controller.dart';

void main() {
  test('효과를 독립적으로 켜고 끄며 그대로는 모두 해제한다', () {
    final c = OnboardingController();
    for (final effect in FaceLayoutMode.values.skip(1)) {
      c.selectFaceMode(effect);
    }
    expect(c.draft.effectiveFaceEffects, hasLength(3));
    c.selectFaceMode(FaceLayoutMode.behindLogo);
    expect(c.draft.effectiveFaceEffects, {
      FaceLayoutMode.paintStroke,
      FaceLayoutMode.belowNeck,
    });
    c.selectFaceMode(FaceLayoutMode.original);
    expect(c.draft.effectiveFaceEffects, isEmpty);
  });

  test('이전 단일 효과 저장본과 새 다중 효과·제호 크기 저장본을 모두 읽는다', () {
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
    expect(reloaded.effectiveFaceEffects, hasLength(3));
    expect(reloaded.mastheadScale, 1.3);
    expect(reloaded.faceMode, FaceLayoutMode.belowNeck);
    final reset = reloaded.copyWith(faceEffects: {});
    expect(reset.faceMode, FaceLayoutMode.original);
    expect(CoverDraft.fromJson(reset.toJson()).effectiveFaceEffects, isEmpty);
    expect(
      reloaded.copyWith(caption: 'keep').effectiveFaceEffects,
      hasLength(3),
    );
  });

  for (final crop in [FaceLayoutMode.behindLogo, FaceLayoutMode.belowNeck]) {
    testWidgets('물감 + $crop: 자르기와 물감 레이어를 함께 렌더링한다', (tester) async {
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
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
