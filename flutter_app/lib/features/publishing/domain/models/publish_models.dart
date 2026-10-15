import '../../../media/domain/models/face_layout_mode.dart';

enum MastheadColor { white, ink }

class PublishRequest {
  final String photoAsset;
  final String colorId;
  final String caption;
  final FaceLayoutMode faceMode;
  final MastheadColor mastheadColor;

  const PublishRequest({
    required this.photoAsset,
    required this.colorId,
    required this.caption,
    required this.faceMode,
    required this.mastheadColor,
  });

  Map<String, dynamic> toJson() => {
    'photoAsset': photoAsset,
    'colorId': colorId,
    'caption': caption,
    'faceMode': faceMode.name,
    'mastheadColor': mastheadColor.name,
  };
}

class PublishResult {
  final bool success;
  final int newIssueCount;
  final String message;

  const PublishResult({
    required this.success,
    required this.newIssueCount,
    required this.message,
  });
}
