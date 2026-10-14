import '../../../media/domain/models/face_layout_mode.dart';
export '../../../media/domain/models/face_layout_mode.dart';

enum OnboardingStep {
  color, // J3
  shoot, // J4
  name,  // J5
  face,  // J6
  done,  // J7
}

class OnboardingDraft {
  final OnboardingStep step;
  final String selectedColorId;
  final String photoAsset;
  final String masthead;
  final FaceLayoutMode faceMode;
  final bool isNameAvailable;

  const OnboardingDraft({
    this.step = OnboardingStep.color,
    this.selectedColorId = 'powder-blue',
    this.photoAsset = 'assets/demo/dana.jpg',
    this.masthead = 'dana',
    this.faceMode = FaceLayoutMode.paintStroke,
    this.isNameAvailable = true,
  });

  OnboardingDraft copyWith({
    OnboardingStep? step,
    String? selectedColorId,
    String? photoAsset,
    String? masthead,
    FaceLayoutMode? faceMode,
    bool? isNameAvailable,
  }) {
    return OnboardingDraft(
      step: step ?? this.step,
      selectedColorId: selectedColorId ?? this.selectedColorId,
      photoAsset: photoAsset ?? this.photoAsset,
      masthead: masthead ?? this.masthead,
      faceMode: faceMode ?? this.faceMode,
      isNameAvailable: isNameAvailable ?? this.isNameAvailable,
    );
  }
}
