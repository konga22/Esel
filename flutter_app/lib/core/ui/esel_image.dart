import 'package:flutter/material.dart';

/// 에셋 이미지를 안전하게 로드하고 실패 시 에러 폴백을 제공하는 공통 위젯
class EselAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const EselAssetImage(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return fallback ??
            Container(
              width: width,
              height: height,
              color: const Color(0xFFF0EFEA),
              child: const Center(
                child: Icon(
                  Icons.photo_outlined,
                  color: Color(0xFFB0AEA5),
                  size: 28,
                ),
              ),
            );
      },
    );
  }
}
