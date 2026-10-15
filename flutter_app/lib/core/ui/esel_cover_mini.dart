import 'package:flutter/widgets.dart';
import '../design/tokens.g.dart';
import '../design/typography.dart';
import 'esel_image.dart';
import 'esel_pressable.dart';

/// 디자인 "작은 표지"(생성기 miniCover): 가판대·서가에 꽂히는 표지.
/// 사진 위 가운데 제호, 아래 40% 그림자 위에 이름(세리프 이탤릭). 모서리 없음, 그림자 하나.
class EselCoverMini extends StatelessWidget {
  final String author;
  final String masthead;
  final String photoAsset;
  final double width;
  final double height;
  final VoidCallback? onTap;

  /// 제호 색. 위쪽이 밝은 사진은 먹.
  final Color mastheadColor;

  /// 이름을 숨기려면 false(서가에서는 이름 대신 Nº를 아래에 따로 쓴다).
  final bool showAuthor;

  /// 사진 위치(BoxFit.cover의 정렬). 디자인의 object-position.
  final Alignment photoAlignment;

  const EselCoverMini({
    super.key,
    required this.author,
    required this.masthead,
    required this.photoAsset,
    this.width = 113.0,
    this.height = 166.0,
    this.onTap,
    this.mastheadColor = const Color(0xFFFFFFFF),
    this.showAuthor = true,
    this.photoAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final mastSize = EselTypography.mastheadSize(
      masthead,
      width,
      max: (width * 0.44).roundToDouble(),
    );

    return EselPressable(
      onTap: onTap,
      semanticsLabel: '$author의 표지 보기',
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          color: EselColors.photo,
          boxShadow: [
            BoxShadow(
              color: Color(0x29292A27),
              blurRadius: 12.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            EselAssetImage(
              photoAsset,
              fit: BoxFit.cover,
              alignment: photoAlignment,
            ),
            if (mastheadColor == const Color(0xFFFFFFFF))
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height * 0.35,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x52000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: height * 0.4,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x8C000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: (height * 0.03).roundToDouble(),
              left: 0,
              right: 0,
              child: ExcludeSemantics(
                child: Text(
                  masthead,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: EselTypography.masthead(
                    fontSize: mastSize,
                    color: mastheadColor,
                  ),
                ),
              ),
            ),
            if (showAuthor)
              Positioned(
                left: (width * 0.06).roundToDouble(),
                right: (width * 0.06).roundToDouble(),
                bottom: (height * 0.035).roundToDouble(),
                child: ExcludeSemantics(
                  child: Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EselTypography.name(
                      fontSize: (mastSize * 0.34).roundToDouble(),
                      color: const Color(0xFFFFFFFF),
                    ).copyWith(height: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
