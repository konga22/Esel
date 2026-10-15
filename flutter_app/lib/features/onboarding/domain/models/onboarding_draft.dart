import '../../../../core/design/tokens.g.dart';
import '../../../media/domain/models/face_layout_mode.dart';
export '../../../media/domain/models/face_layout_mode.dart';

enum OnboardingStep {
  color, // J3
  shoot, // J4
  name, // J5
  face, // J6
  done, // J7
}

class OnboardingDraft {
  final OnboardingStep step;

  /// 창간호의 색. 오늘 후보 중에서 고른다(P17). 고르기 전에는 null.
  final EselPaint? color;
  final String photoAsset;
  final String masthead;
  final FaceLayoutMode faceMode;
  final bool isNameAvailable;

  const OnboardingDraft({
    this.step = OnboardingStep.color,
    this.color,
    this.photoAsset = 'assets/demo/dana.jpg',
    this.masthead = 'dana',
    this.faceMode = FaceLayoutMode.paintStroke,
    this.isNameAvailable = true,
  });

  OnboardingDraft copyWith({
    OnboardingStep? step,
    EselPaint? color,
    String? photoAsset,
    String? masthead,
    FaceLayoutMode? faceMode,
    bool? isNameAvailable,
  }) {
    return OnboardingDraft(
      step: step ?? this.step,
      color: color ?? this.color,
      photoAsset: photoAsset ?? this.photoAsset,
      masthead: masthead ?? this.masthead,
      faceMode: faceMode ?? this.faceMode,
      isNameAvailable: isNameAvailable ?? this.isNameAvailable,
    );
  }
}
