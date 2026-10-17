import '../../../../core/design/tokens.g.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../../../media/domain/models/face_layout_mode.dart';
export '../../../media/domain/models/face_layout_mode.dart';

/// 창간 단계(P13). 색 → 촬영 → 제호 → 얼굴 → 창간호, 한 화면에 결정 하나.
enum OnboardingStep {
  color, // J3
  shoot, // J4
  name, // J5
  face, // J6
  done, // J7 창간호
}

/// 제호 중복 확인 상태. "쓸 수 있는 이름이에요"는 확인이 끝났을 때만 보인다(DEV-06).
enum MastheadStatus { tooShort, checking, available, taken, unknown }

class OnboardingDraft {
  final OnboardingStep step;

  /// 창간호의 색. 오늘 후보 중에서 고른다(P17). 고르기 전에는 null.
  final EselPaint? color;

  /// 기기 보관함에 들인 사진 경로. 고르기 전에는 빈 문자열.
  final String photoPath;

  /// 사용자가 입력한 제호(소문자 a–z, 10자까지). 예시 인물 이름으로 채워 두지 않는다.
  final String masthead;
  final MastheadStatus mastheadStatus;
  final FaceLayoutMode faceMode;

  /// 얼굴 가운데(원본 사진에 대한 비율). 지정 전에는 [facePlaced]가 false.
  final double faceX;
  final double faceY;
  final double faceWidth;
  final bool facePlaced;

  /// 발행된 창간호(Nº 001). done 단계에서만 있다.
  final CoverDraft? issue;

  /// 나를 포함한 오늘 같은 색 인원(공개 숫자, P18).
  final int sameColorCount;

  const OnboardingDraft({
    this.step = OnboardingStep.color,
    this.color,
    this.photoPath = '',
    this.masthead = '',
    this.mastheadStatus = MastheadStatus.tooShort,
    this.faceMode = FaceLayoutMode.paintStroke,
    this.faceX = .5,
    this.faceY = .3,
    this.faceWidth = CoverDraft.defaultFaceWidth,
    this.facePlaced = false,
    this.issue,
    this.sameColorCount = 1,
  });

  OnboardingDraft copyWith({
    OnboardingStep? step,
    EselPaint? color,
    String? photoPath,
    String? masthead,
    MastheadStatus? mastheadStatus,
    FaceLayoutMode? faceMode,
    double? faceX,
    double? faceY,
    double? faceWidth,
    bool? facePlaced,
    CoverDraft? issue,
    int? sameColorCount,
  }) {
    return OnboardingDraft(
      step: step ?? this.step,
      color: color ?? this.color,
      photoPath: photoPath ?? this.photoPath,
      masthead: masthead ?? this.masthead,
      mastheadStatus: mastheadStatus ?? this.mastheadStatus,
      faceMode: faceMode ?? this.faceMode,
      faceX: faceX ?? this.faceX,
      faceY: faceY ?? this.faceY,
      faceWidth: faceWidth ?? this.faceWidth,
      facePlaced: facePlaced ?? this.facePlaced,
      issue: issue ?? this.issue,
      sameColorCount: sameColorCount ?? this.sameColorCount,
    );
  }

  /// 미리보기·발행에 쓰는 표지. 얼굴 위치를 정한 뒤에만 확인된 표지가 된다(P11).
  CoverDraft toCover({required String id, required DateTime now}) => CoverDraft(
    id: id,
    photoPath: photoPath,
    masthead: masthead,
    color: color ?? EselPaint.camel,
    faceMode: faceMode,
    faceX: faceX,
    faceY: faceY,
    faceWidth: faceWidth,
    faceConfirmed: facePlaced,
    updatedAt: now,
  );
}
