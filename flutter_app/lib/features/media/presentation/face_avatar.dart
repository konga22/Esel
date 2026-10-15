import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../../../core/design/tokens.g.dart';
import '../domain/models/face_box.dart';
import 'photo_ratio_builder.dart';

/// 얼굴이 원의 60%를 채우는 둥근 아바타(디자인 생성기 avatar). 장식이라 읽지 않는다.
class FaceAvatar extends StatelessWidget {
  final ImageProvider image;
  final FaceBox face;
  final double size;

  const FaceAvatar({
    super.key,
    required this.image,
    required this.face,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: ColoredBox(
            color: const Color(0xFFE9E9E6),
            child: PhotoRatioBuilder(
              image: image,
              builder: (context, ratio) {
                final w = math.max(size, 0.6 * size / face.width);
                final h = w * ratio;
                final left = (size / 2 - face.x * w)
                    .clamp(size - w, 0.0)
                    .toDouble();
                final top = (size / 2 - face.y * h)
                    .clamp(math.min(0.0, size - h), 0.0)
                    .toDouble();
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: left,
                      top: top,
                      width: w,
                      height: h,
                      child: Image(
                        image: image,
                        fit: BoxFit.fill,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: EselColors.photo),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
