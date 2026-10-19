import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../../core/errors/failures.dart';
import '../../../core/network/http_client.dart';
import '../../drafts/domain/cover_draft.dart';
import '../../garments/domain/garment.dart';
import '../../issue/data/sources/issue_remote_source.dart';
import '../../media/domain/models/face_box.dart';
import '../../media/domain/models/face_layout_mode.dart';
import '../../media/domain/rules/media_upload_policy.dart';
import '../../media/presentation/controllers/media_upload_controller.dart';
import '../../media/presentation/cover_photo.dart';
import '../../media/presentation/publish_photo_renderer.dart';

/// 기존 서버 DTO만 사용한다. 사인 뒤로는 서버 값으로 변환하기 전에 차단한다.
class PublishingRemoteSource {
  final AppHttpClient http;
  final MediaUploadController uploads;
  final Future<Uint8List> Function(String path) readPhoto;
  PublishingRemoteSource(this.http, this.uploads, {required this.readPhoto});

  static String faceMode(CoverDraft draft) {
    validateMediaUpload(draft);
    if (faceCropMode(draft.effectiveFaceEffects) == FaceLayoutMode.belowNeck) {
      return 'NECK_DOWN';
    }
    return draft.effectiveFaceEffects.contains(FaceLayoutMode.paintStroke)
        ? 'PAINT'
        : 'PLAIN';
  }

  static Map<String, dynamic> garmentInput(
    Garment garment,
    CoverDraft draft,
    double photoRatio, {
    required bool knownServerId,
  }) {
    final rect = CoverPhoto.photoRect(
      box: const ui.Size(1080, 1440),
      photoRatio: photoRatio,
      face: FaceBox(draft.faceX, draft.faceY, draft.faceWidth),
      mode: faceCropMode(draft.effectiveFaceEffects),
    );
    final x = garment.x == null
        ? null
        : (rect.left + garment.x! * rect.width) / 1080;
    final y = garment.y == null
        ? null
        : (rect.top + garment.y! * rect.height) / 1440;
    final visible =
        x != null && y != null && x >= 0 && x <= 1 && y >= 0 && y <= 1;
    return {
      if (knownServerId) 'garmentId': garment.id,
      'kind': garment.kind,
      'name': garment.name,
      'note': garment.note,
      'todayColor': garment.todayColor,
      if (visible) 'x': x,
      if (visible) 'y': y,
    };
  }

  Future<CoverDraft> publish(CoverDraft draft) async {
    final mode = faceMode(draft);
    final error = draft.validationError;
    if (error != null) {
      throw RuleFailure(error);
    }
    if (draft.caption.trim().runes.length > 280) {
      throw const RuleFailure('문구는 280자 이내로 입력해 주세요.');
    }
    if (draft.challengeId != null || draft.previousIssueId != null) {
      throw const RuleFailure('이번 주 주제·같은 옷 참여는 아직 시연 모드에서만 사용할 수 있어요.');
    }
    final source = uploads.source;
    final version = source.generation;
    void checkOwner() {
      if (draft.ownerId.isEmpty ||
          source.ownerId != draft.ownerId ||
          source.generation != version) {
        throw const AuthFailure('계정이 변경됐어요. 내 계정에서 다시 시도해 주세요.');
      }
    }

    checkOwner();
    final bytes = await readPhoto(draft.photoPath);
    checkOwner();
    final image = await PublishPhotoRenderer.decodeSource(bytes);
    final ratio = image.height / image.width;
    image.dispose();
    // UUID 모양만 믿지 않는다. 실제 내 옷 목록에 있고 내용도 같을 때만 재사용한다.
    final wanted = draft.garments
        .where(
          (g) => RegExp(
            r'^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$',
          ).hasMatch(g.id),
        )
        .map((g) => g.id)
        .toSet();
    final known = <String, Garment>{};
    String? cursor;
    final seen = <String>{};
    if (wanted.isNotEmpty) {
      do {
        final page = await http.get(
          '/me/garments',
          queryParams: {'cursor': ?cursor},
        );
        checkOwner();
        for (final row in page['items'] as List) {
          final item = Garment.fromJson(Map<String, dynamic>.from(row as Map));
          if (wanted.contains(item.id)) {
            known[item.id] = item;
          }
        }
        cursor = page['nextCursor'] as String?;
        if (cursor != null && !seen.add(cursor)) {
          throw const FormatException('옷 목록 페이지를 확인해 주세요.');
        }
      } while (cursor != null && !wanted.every(known.containsKey));
    }
    checkOwner();
    final mediaId = await uploads.upload(draft, readPhoto: () async => bytes);
    checkOwner();
    final data = await http.post(
      '/issues',
      body: {
        'mediaId': mediaId,
        'caption': draft.caption.trim(),
        'faceMode': mode,
        'garments': [
          for (final g in draft.garments)
            garmentInput(
              g,
              draft,
              ratio,
              knownServerId:
                  known[g.id]?.kind == g.kind &&
                  known[g.id]?.name == g.name &&
                  known[g.id]?.note == g.note,
            ),
        ],
      },
    );
    checkOwner();
    final issue = parseServerIssue(data);
    return CoverDraft(
      id: issue.id,
      ownerId: draft.ownerId,
      photoPath: draft.photoPath,
      masthead: issue.masthead,
      caption: issue.caption,
      color: issue.color,
      issueNumber: issue.number,
      publishedOn: issue.date.key,
      updatedAt: issue.publishedAt,
      faceEffects: draft.effectiveFaceEffects,
      faceConfirmed: true,
      faceX: draft.faceX,
      faceY: draft.faceY,
      faceWidth: draft.faceWidth,
      mastheadScale: draft.mastheadScale,
      garments: draft.garments,
    );
  }
}
