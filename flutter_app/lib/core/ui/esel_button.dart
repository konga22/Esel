import 'package:flutter/widgets.dart';
import '../design/tokens.g.dart';
import '../design/typography.dart';
import 'esel_pressable.dart';

enum EselButtonVariant { primary, secondary, text }

class EselButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final EselButtonVariant variant;
  final bool? isPrimary;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final double? width;
  final bool enabled;

  const EselButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = EselButtonVariant.primary,
    this.isPrimary,
    this.icon,
    this.leading,
    this.trailing,
    this.width,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    final resolvedVariant = isPrimary != null
        ? (isPrimary! ? EselButtonVariant.primary : EselButtonVariant.secondary)
        : variant;

    switch (resolvedVariant) {
      case EselButtonVariant.primary:
        bg = enabled ? EselColors.ink : EselColors.sub;
        fg = EselColors.paper;
        break;
      case EselButtonVariant.secondary:
        bg = EselColors.paper;
        fg = enabled ? EselColors.ink : EselColors.muted;
        border = Border.all(color: EselColors.hairline);
        break;
      case EselButtonVariant.text:
        bg = const Color(0x00000000);
        fg = enabled ? EselColors.ink : EselColors.muted;
        break;
    }

    final leadWidget =
        leading ?? (icon != null ? Icon(icon, size: 18, color: fg) : null);

    return EselPressable(
      onTap: enabled ? onTap : null,
      enabled: enabled,
      semanticsLabel: label,
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: EselSizes.button),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(EselRadius.pill),
          border: border,
        ),
        child: Row(
          mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadWidget != null) ...[leadWidget, const SizedBox(width: 8.0)],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: EselTypography.label(fontSize: 15.0, color: fg),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8.0), trailing!],
          ],
        ),
      ),
    );
  }
}
