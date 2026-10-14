import 'package:flutter/widgets.dart';
import '../design/tokens.g.dart';
import '../design/typography.dart';
import '../../features/onboarding/domain/rules/masthead_rule.dart';
import 'esel_pressable.dart';

class EselCoverMini extends StatelessWidget {
  final String author;
  final String masthead;
  final String photoAsset;
  final EselPaint color;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final int? issueNumber;

  const EselCoverMini({
    super.key,
    required this.author,
    required this.masthead,
    required this.photoAsset,
    required this.color,
    this.width = 110.0,
    this.height = 154.0,
    this.onTap,
    this.issueNumber,
  });

  @override
  Widget build(BuildContext context) {
    final baseFontSize = width * 0.44;
    final mastSize = MastheadRule.calculateFontSize(
      masthead,
      width: width,
      max: baseFontSize,
    );

    return EselPressable(
      onTap: onTap,
      semanticsLabel: '$author의 표지 보기, 제호 $masthead',
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(EselRadius.spreadPhoto),
          boxShadow: const [
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
            // Photo
            Image.asset(
              photoAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: EselColors.photo),
            ),

            // Top gradient shade for white masthead
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
                    colors: [Color(0x66000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),

            // Bottom gradient shade for author name
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: height * 0.45,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x8C000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),

            // Masthead text
            Positioned(
              top: height * 0.03,
              left: 0,
              right: 0,
              child: Text(
                masthead,
                textAlign: TextAlign.center,
                style: EselTypography.masthead(
                  fontSize: mastSize,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),

            // Bottom author name and issue number
            Positioned(
              bottom: height * 0.04,
              left: width * 0.06,
              right: width * 0.06,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: EselTypography.name(
                        fontSize: baseFontSize * 0.34,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                  if (issueNumber != null) ...[
                    const SizedBox(width: 4.0),
                    Text(
                      'Nº $issueNumber',
                      style: EselTypography.meta(
                        fontSize: 9.0,
                        color: const Color(0xCCFFFFFF),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
