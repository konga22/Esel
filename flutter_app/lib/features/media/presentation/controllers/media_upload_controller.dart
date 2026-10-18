import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../../data/media_remote_source.dart';
import '../../domain/rules/media_upload_policy.dart';
import '../publish_photo_renderer.dart';

/// #30의 사진 준비·업로드 경계. #31은 이 결과의 mediaId로 별도 발행한다.
/// 원본을 직접 올리거나 렌더링 실패를 원본 업로드로 우회하지 않는다.
class MediaUploadController {
  final MediaRemoteSource source;
  MediaUploadController(this.source);

  Future<String> upload(
    CoverDraft draft, {
    required Future<Uint8List> Function() readPhoto,
  }) async {
    validateMediaUpload(draft);
    final generation = source.generation;
    void checkOwner() {
      if (draft.ownerId.isEmpty ||
          source.ownerId != draft.ownerId ||
          generation != source.generation) {
        throw const AuthFailure('내 계정의 사진만 올릴 수 있어요. 계정을 확인해 주세요.');
      }
    }

    checkOwner();
    final original = await readPhoto();
    checkOwner();
    final rendered = await PublishPhotoRenderer.render(draft, original);
    checkOwner();
    return source.upload(rendered);
  }
}
