import 'package:flutter/material.dart';
import '../../../core/design/tokens.g.dart';
import '../../drafts/domain/cover_draft.dart';
import '../../media/domain/models/face_layout_mode.dart';
import '../../media/presentation/cover_photo.dart';
import '../../media/presentation/cover_preview.dart';
import '../../media/presentation/photo_ratio_builder.dart';
import '../domain/models/public_issue.dart';
import 'issue_photo.dart';

/// 팔레트·스케치북·자세히 보기에서 같은 얼굴 연출과 원본 좌표 변환을 쓴다.
class CanvasPhoto extends StatelessWidget {
  final PublicIssue issue;
  final bool cover, tags;
  final String? selected;
  final ValueChanged<String>? onTag;
  const CanvasPhoto({
    super.key,
    required this.issue,
    this.cover = false,
    this.tags = false,
    this.selected,
    this.onTag,
  });
  @override
  Widget build(BuildContext context) {
    if (issue.photo.isEmpty) {
      return const ColoredBox(
        color: EselColors.photo,
        child: Center(child: Text('사진 제공 준비 중')),
      );
    }
    final effects = normalizeFaceEffects(issue.faceEffects ?? {issue.faceMode});
    final crop = faceCropMode(effects);
    return PhotoRatioBuilder(
      image: issuePhotoProvider(issue.photo),
      builder: (context, ratio) => LayoutBuilder(
        builder: (context, box) {
          final rect = CoverPhoto.photoRect(
            box: Size(box.maxWidth, box.maxHeight),
            photoRatio: issue.photoRatio ?? ratio,
            face: issue.face,
            mode: crop,
          );
          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoverPreview(
                  aspectRatio: null,
                  draft: CoverDraft(
                    id: issue.id,
                    photoPath: issue.photo,
                    masthead: issue.masthead,
                    color: issue.color,
                    faceMode: issue.faceMode,
                    faceEffects: effects,
                    faceX: issue.face.x,
                    faceY: issue.face.y,
                    faceWidth: issue.face.width,
                    whiteTitle: !issue.inkMasthead,
                    mastheadScale: issue.mastheadScale,
                    updatedAt: issue.publishedAt,
                  ),
                  chrome: cover || crop == FaceLayoutMode.behindLogo,
                ),
                if (tags)
                  for (final garment in issue.garments.where(
                    (v) => v.x != null,
                  ))
                    if (rect.left + rect.width * garment.x! >= 0 &&
                        rect.left + rect.width * garment.x! <= box.maxWidth &&
                        rect.top + rect.height * garment.y! >= 0 &&
                        rect.top + rect.height * garment.y! <= box.maxHeight)
                      Positioned(
                        left: (rect.left + rect.width * garment.x! - 24).clamp(
                          0,
                          (box.maxWidth - 48).clamp(0, double.infinity),
                        ),
                        top: (rect.top + rect.height * garment.y! - 24).clamp(
                          0,
                          (box.maxHeight - 48).clamp(0, double.infinity),
                        ),
                        child: IconButton(
                          key: ValueKey('garment-tag-${garment.id}'),
                          tooltip: '착용 정보 · ${garment.label}',
                          onPressed: () => onTag?.call(garment.id),
                          icon: Icon(
                            selected == garment.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: Colors.white,
                          ),
                        ),
                      ),
                if (issue.garments.isNotEmpty)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: ActionChip(
                      label: Text('착용 ${issue.garments.length}'),
                      onPressed: () => onTag?.call(issue.garments.first.id),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
