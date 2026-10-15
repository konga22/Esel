import 'package:flutter/widgets.dart';

/// 사진을 읽어 세로/가로 비율을 알려 준다. 읽기 전에는 [fallback](세로 사진 3:4).
class PhotoRatioBuilder extends StatefulWidget {
  final ImageProvider image;
  final double fallback;
  final Widget Function(BuildContext context, double ratio) builder;

  const PhotoRatioBuilder({
    super.key,
    required this.image,
    required this.builder,
    this.fallback = 4 / 3,
  });

  @override
  State<PhotoRatioBuilder> createState() => _PhotoRatioBuilderState();
}

class _PhotoRatioBuilderState extends State<PhotoRatioBuilder> {
  double? _ratio;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(PhotoRatioBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _ratio = null;
      _resolve();
    }
  }

  void _resolve() {
    _stop();
    final stream = widget.image.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      final ratio = info.image.height / info.image.width;
      if (mounted && ratio != _ratio) setState(() => _ratio = ratio);
    }, onError: (_, _) {});
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _stop() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _ratio ?? widget.fallback);
}
