import 'package:flutter/foundation.dart';
import '../../../../core/design/tokens.g.dart';
import '../../domain/models/onboarding_draft.dart';
import '../../domain/rules/masthead_rule.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingDraft _draft = const OnboardingDraft();

  OnboardingDraft get draft => _draft;
  OnboardingStep get currentStep => _draft.step;

  final List<String> availablePhotos = const [
    'assets/demo/dana.jpg',
    'assets/models/m01.jpg',
    'assets/models/m02.jpg',
    'assets/models/m03.jpg',
    'assets/models/m04.jpg',
    'assets/models/m05.jpg',
  ];

  void selectColor(EselPaint color) {
    _draft = _draft.copyWith(color: color);
    notifyListeners();
  }

  void selectPhoto(String photoAsset) {
    _draft = _draft.copyWith(photoAsset: photoAsset);
    notifyListeners();
  }

  void cycleNextPhoto() {
    final curIdx = availablePhotos.indexOf(_draft.photoAsset);
    final nextIdx = (curIdx + 1) % availablePhotos.length;
    selectPhoto(availablePhotos[nextIdx]);
  }

  void updateMasthead(String input) {
    final sanitized = MastheadRule.sanitize(input);
    final isValid = MastheadRule.isValid(sanitized);
    // Reserved / Taken names check (mock)
    final isAvailable = isValid && sanitized != 'admin' && sanitized != 'esel';
    _draft = _draft.copyWith(masthead: sanitized, isNameAvailable: isAvailable);
    notifyListeners();
  }

  void selectFaceMode(FaceLayoutMode mode) {
    _draft = _draft.copyWith(faceMode: mode);
    notifyListeners();
  }

  bool canProceed() {
    switch (_draft.step) {
      case OnboardingStep.color:
        return _draft.color != null;
      case OnboardingStep.shoot:
        return _draft.photoAsset.isNotEmpty;
      case OnboardingStep.name:
        return _draft.isNameAvailable && MastheadRule.isValid(_draft.masthead);
      case OnboardingStep.face:
        return true;
      case OnboardingStep.done:
        return true;
    }
  }

  void nextStep() {
    if (!canProceed()) return;
    switch (_draft.step) {
      case OnboardingStep.color:
        _draft = _draft.copyWith(step: OnboardingStep.shoot);
        break;
      case OnboardingStep.shoot:
        _draft = _draft.copyWith(step: OnboardingStep.name);
        break;
      case OnboardingStep.name:
        _draft = _draft.copyWith(step: OnboardingStep.face);
        break;
      case OnboardingStep.face:
        _draft = _draft.copyWith(step: OnboardingStep.done);
        break;
      case OnboardingStep.done:
        break;
    }
    notifyListeners();
  }

  void prevStep() {
    switch (_draft.step) {
      case OnboardingStep.color:
        break;
      case OnboardingStep.shoot:
        _draft = _draft.copyWith(step: OnboardingStep.color);
        break;
      case OnboardingStep.name:
        _draft = _draft.copyWith(step: OnboardingStep.shoot);
        break;
      case OnboardingStep.face:
        _draft = _draft.copyWith(step: OnboardingStep.name);
        break;
      case OnboardingStep.done:
        _draft = _draft.copyWith(step: OnboardingStep.face);
        break;
    }
    notifyListeners();
  }

  void reset() {
    _draft = const OnboardingDraft();
    notifyListeners();
  }
}
