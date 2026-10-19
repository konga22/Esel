import '../domain/rules/media_upload_policy.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../../../core/design/tokens.g.dart';
import '../../../core/errors/failures.dart';
import '../../drafts/domain/cover_draft.dart';
import '../domain/models/face_box.dart';
import '../domain/models/face_layout_mode.dart';
import 'cover_photo.dart';

/// 사인·캡션·위치 좌표 없이 얼굴 연출이 적용된 픽셀만 만든다. 원본 바이트는 업로드하지 않는다.
class PublishPhotoRenderer {
  static Future<Uint8List> render(
    CoverDraft draft,
    Uint8List source, {
    int width = 1080,
  }) async {
    validateMediaUpload(draft);
    final effects = draft.effectiveFaceEffects;
    final mode = faceCropMode(effects);
    if (width < 120 || width > 1800) {
      throw const RuleFailure('사진 출력 크기를 확인해 주세요.');
    }
    final codec = await ui.instantiateImageCodec(source);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final image = frame.image;
    ui.Image? paint;
    try {
      final size = ui.Size(width.toDouble(), width * 4 / 3);
      final face = FaceBox(draft.faceX, draft.faceY, draft.faceWidth);
      final rect = CoverPhoto.photoRect(
        box: size,
        photoRatio: image.height / image.width,
        face: face,
        mode: mode,
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)
        ..clipRect(ui.Offset.zero & size)
        ..drawColor(EselColors.photo, ui.BlendMode.src);
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      if (effects.contains(FaceLayoutMode.paintStroke)) {
        final asset = await rootBundle.load(
          EselPaints.of(draft.color).assetPath,
        );
        final pc = await ui.instantiateImageCodec(
          asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
        );
        paint = (await pc.getNextFrame()).image;
        pc.dispose();
        final stroke = CoverPhoto.strokeRect(rect, face);
        canvas.save();
        canvas.translate(stroke.center.dx, stroke.center.dy);
        canvas.rotate(-10 * math.pi / 180);
        canvas.drawImageRect(
          paint,
          ui.Rect.fromLTWH(
            0,
            0,
            paint.width.toDouble(),
            paint.height.toDouble(),
          ),
          ui.Rect.fromCenter(
            center: ui.Offset.zero,
            width: stroke.width,
            height: stroke.height,
          ),
          ui.Paint()..filterQuality = ui.FilterQuality.high,
        );
        canvas.restore();
      }
      final picture = recorder.endRecording();
      final rendered = await picture.toImage(
        size.width.round(),
        size.height.round(),
      );
      picture.dispose();
      try {
        final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
        if (data == null || data.lengthInBytes > 15 * 1024 * 1024) {
          throw const RuleFailure('사진은 15MB 이하로 준비해 주세요.');
        }
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        rendered.dispose();
      }
    } finally {
      image.dispose();
      paint?.dispose();
    }
  }
}
