import 'package:flutter/material.dart';
import '../../drafts/data/local_library.dart';

class DevicePreferences extends StatelessWidget {
  final LocalLibrary library;
  final Widget child;
  const DevicePreferences({
    super.key,
    required this.library,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: library,
    builder: (context, _) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          disableAnimations: media.disableAnimations || library.reduceMotion,
          highContrast: media.highContrast || library.reduceTransparency,
          textScaler: library.largeText && media.textScaler.scale(1) < 1.2
              ? const TextScaler.linear(1.2)
              : media.textScaler,
        ),
        child: child,
      );
    },
  );
}
