import 'package:flutter/widgets.dart';
import '../design/tokens.g.dart';

/// Base pressable widget adhering to Esel motion & accessibility rules:
/// - Minimum 48x48 hit target
/// - Press feedback: scale 0.97, 160ms ease-out
/// - Respects prefers-reduced-motion (instant transition when disableAnimations is true)
class EselPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final bool enabled;
  final HitTestBehavior behavior;

  const EselPressable({
    super.key,
    required this.child,
    this.onTap,
    this.semanticsLabel,
    this.enabled = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<EselPressable> createState() => _EselPressableState();
}

class _EselPressableState extends State<EselPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: EselMotion.press);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: EselMotion.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.onTap == null) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled || widget.onTap == null) return;
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.onTap == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final disableAnimations = media?.disableAnimations ?? false;

    Widget content = widget.child;

    if (!disableAnimations) {
      content = ScaleTransition(scale: _scaleAnimation, child: content);
    }

    return Semantics(
      button: true,
      enabled: widget.enabled && widget.onTap != null,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.enabled ? widget.onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: EselSizes.touch,
            minHeight: EselSizes.touch,
          ),
          child: Center(widthFactor: 1.0, heightFactor: 1.0, child: content),
        ),
      ),
    );
  }
}
