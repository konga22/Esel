import 'package:flutter/widgets.dart';
import '../design/tokens.g.dart';
import '../design/typography.dart';
import 'esel_pressable.dart';

class EselChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool? isActive;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool isLocked;

  const EselChip({
    super.key,
    required this.label,
    this.selected = false,
    this.isActive,
    this.onTap,
    this.leading,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSel = isActive ?? selected;
    final bg = isSel ? EselColors.ink : EselColors.paper;
    final fg = isSel ? EselColors.paper : EselColors.ink;
    final border = isSel ? null : Border.all(color: EselColors.hairline);

    return EselPressable(
      onTap: onTap,
      semanticsLabel: '$label ${isSel ? "선택됨" : ""} ${isLocked ? "잠김" : ""}',
      child: Container(
        height: EselSizes.chip, // 38px
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(EselRadius.pill),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6.0)],
            Text(label, style: EselTypography.label(fontSize: 13.0, color: fg)),
          ],
        ),
      ),
    );
  }
}
