import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../../domain/models/onboarding_draft.dart';
import '../../domain/rules/masthead_rule.dart';

/// 창간 흐름(J3~J7)의 상태. 사진은 화면이 기기 보관함에 들여온 경로만 받는다.
class OnboardingController extends ChangeNotifier {
  /// 제호를 쓸 수 있는지 묻는다. 확인하지 못하면 null.
  final Future<bool?> Function(String masthead)? checkMasthead;

  OnboardingController({this.checkMasthead});

  OnboardingDraft _draft = const OnboardingDraft();

  OnboardingDraft get draft => _draft;
  OnboardingStep get currentStep => _draft.step;

  void selectColor(EselPaint color) {
    _draft = _draft.copyWith(color: color);
    notifyListeners();
  }

  /// 찍거나 고른 사진. 사진이 바뀌면 얼굴 위치를 다시 정해야 한다(P11).
  void setPhoto(String photoPath) {
    _draft = _draft.copyWith(photoPath: photoPath, facePlaced: false);
    notifyListeners();
  }

  /// 입력 중에 영문 소문자 외의 글자는 걸러 내고 10자에서 멈춘다(P14). 걸러 낸 값을 돌려준다.
  String updateMasthead(String input) {
    final sanitized = MastheadRule.sanitize(input);
    final valid = MastheadRule.isValid(sanitized);
    final check = checkMasthead;
    _draft = _draft.copyWith(
      masthead: sanitized,
      mastheadStatus: !valid
          ? MastheadStatus.tooShort
          : check == null
          ? MastheadStatus.available
          : MastheadStatus.checking,
    );
    notifyListeners();
    if (valid && check != null) _check(sanitized, check);
    return sanitized;
  }

  Future<void> _check(String name, Future<bool?> Function(String) check) async {
    final available = await check(name);
    // 늦게 온 이전 이름의 결과는 버린다.
    if (_draft.masthead != name) return;
    _draft = _draft.copyWith(
      mastheadStatus: available == null
          ? MastheadStatus.unknown
          : available
          ? MastheadStatus.available
          : MastheadStatus.taken,
    );
    notifyListeners();
  }

  void selectFaceMode(FaceLayoutMode mode) {
    _draft = _draft.copyWith(faceMode: mode);
    notifyListeners();
  }

  /// 표지에서 얼굴 가운데를 누른 자리(표지에 대한 비율).
  void placeFace(Offset point) {
    _draft = _draft.copyWith(
      faceX: point.dx.clamp(0.0, 1.0),
      faceY: point.dy.clamp(0.0, 1.0),
      facePlaced: true,
    );
    notifyListeners();
  }

  bool canProceed() {
    switch (_draft.step) {
      case OnboardingStep.color:
        return _draft.color != null;
      case OnboardingStep.shoot:
        return _draft.photoPath.isNotEmpty;
      case OnboardingStep.name:
        return _draft.mastheadStatus == MastheadStatus.available;
      case OnboardingStep.face:
        return _draft.facePlaced;
      case OnboardingStep.done:
        return true;
    }
  }

  void nextStep() {
    if (!canProceed()) return;
    final next = switch (_draft.step) {
      OnboardingStep.color => OnboardingStep.shoot,
      OnboardingStep.shoot => OnboardingStep.name,
      OnboardingStep.name => OnboardingStep.face,
      // 얼굴 다음(창간호)은 실제로 발행한 뒤 [markFounded]로만 간다.
      OnboardingStep.face => OnboardingStep.face,
      OnboardingStep.done => OnboardingStep.done,
    };
    _draft = _draft.copyWith(step: next);
    notifyListeners();
  }

  void prevStep() {
    final prev = switch (_draft.step) {
      OnboardingStep.color => OnboardingStep.color,
      OnboardingStep.shoot => OnboardingStep.color,
      OnboardingStep.name => OnboardingStep.shoot,
      OnboardingStep.face => OnboardingStep.name,
      // 창간호를 낸 뒤에는 되돌아가지 않는다.
      OnboardingStep.done => OnboardingStep.done,
    };
    _draft = _draft.copyWith(step: prev);
    notifyListeners();
  }

  /// 창간호(Nº 001)가 발행됐다.
  void markFounded(CoverDraft issue) {
    _draft = _draft.copyWith(step: OnboardingStep.done, issue: issue);
    notifyListeners();
  }

  void reset() {
    _draft = const OnboardingDraft();
    notifyListeners();
  }
}
