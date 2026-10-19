import '../../../../core/errors/failures.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../models/face_layout_mode.dart';

/// 2026-10-19 사용자 확인. 해제 조건: docs/flutter/MEDIA_UPLOAD_HANDOFF.md.
/// 사인 글자를 제외하면 가렸던 얼굴이 드러날 수 있으므로 서버 업로드를 보류한다.
/// 기존 로컬 미리보기·저장·발행 규칙은 바꾸지 않는다.
void validateMediaUpload(CoverDraft draft) {
  if (faceCropMode(draft.effectiveFaceEffects) == FaceLayoutMode.behindLogo) {
    throw const RuleFailure(
      '사인 글자를 빼면 가렸던 얼굴이 드러날 수 있어요. 서버에 올리려면 다른 얼굴 연출을 골라 주세요.',
      code: 'SIGNATURE_UPLOAD_PENDING',
    );
  }
  if (!draft.faceConfirmed) throw const RuleFailure('얼굴 위치와 연출을 먼저 확인해 주세요.');
}
