import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../app/dependencies/service_locator.dart';
import '../../../core/design/tokens.g.dart';
import '../../../core/errors/failures.dart';
import '../data/media_remote_source.dart';

/// 이미 얼굴 연출이 적용된 서버 사진. 다시 얼굴을 자르거나 물감을 덧그리지 않는다.
/// 인증 요청과 캐시는 MediaRemoteSource에 두고 디스크에는 저장하지 않는다.
class RemoteMediaPhoto extends StatefulWidget {
  final String id;
  final bool thumbnail;

  /// 흐린 맛보기 배경처럼 조작할 수 없는 장식 사진은 상태 UI를 그리지 않는다.
  final bool decorative;
  final String semanticLabel;
  final MediaRemoteSource? source;
  const RemoteMediaPhoto({
    super.key,
    required this.id,
    this.thumbnail = false,
    this.decorative = false,
    this.semanticLabel = '착장 사진',
    this.source,
  });
  @override
  State<RemoteMediaPhoto> createState() => _RemoteMediaPhotoState();
}

class _RemoteMediaPhotoState extends State<RemoteMediaPhoto> {
  late MediaRemoteSource _source;
  late Future<Uint8List> _photo;
  @override
  void initState() {
    super.initState();
    _source = widget.source ?? ServiceLocator().mediaSource;
    _source.addListener(_ownerChanged);
    _load();
  }

  void _load({bool retry = false}) {
    _photo = _source.photo(
      widget.id,
      thumbnail: widget.thumbnail,
      retry: retry,
    );
    // 빠른 실패는 다음 프레임의 FutureBuilder 구독보다 먼저 도착할 수 있다.
    // 즉시 오류 핸들러를 연결하되 원래 Future의 오류는 화면에서 그대로 안내한다.
    _photo.ignore();
  }

  void _ownerChanged() {
    if (mounted) setState(_load);
  }

  @override
  void didUpdateWidget(RemoteMediaPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    final source = widget.source ?? ServiceLocator().mediaSource;
    if (source != _source) {
      _source.removeListener(_ownerChanged);
      _source = source;
      _source.addListener(_ownerChanged);
    }
    if (source != (oldWidget.source ?? ServiceLocator().mediaSource) ||
        widget.id != oldWidget.id ||
        widget.thumbnail != oldWidget.thumbnail) {
      _load();
    }
  }

  @override
  void dispose() {
    _source.removeListener(_ownerChanged);
    super.dispose();
  }

  Widget _error({bool notFound = false}) {
    if (widget.decorative) return const SizedBox.shrink();
    final message = notFound ? '사진 제공 준비 중' : '사진을 불러오지 못했어요.';
    void retry() => setState(() => _load(retry: true));
    return ColoredBox(
      color: EselColors.photo,
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxHeight < 150 || box.maxWidth < 150) {
            return Center(
              child: IconButton(
                tooltip: '$message 사진 다시 보기',
                onPressed: retry,
                icon: const Icon(Icons.refresh),
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center),
                TextButton(onPressed: retry, child: const Text('사진 다시 보기')),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    // 계정·항목이 바뀌면 FutureBuilder가 이전 계정의 완성된 사진을 유지하지 않도록 한다.
    key: ValueKey('${_source.generation}|${widget.id}|${widget.thumbnail}'),
    future: _photo,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        if (widget.decorative) return const SizedBox.shrink();
        return const ColoredBox(
          color: EselColors.photo,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return _error(notFound: snapshot.error is NotFoundFailure);
      }
      return Image.memory(
        snapshot.data!,
        fit: BoxFit.cover,
        gaplessPlayback: false,
        semanticLabel: widget.semanticLabel,
        errorBuilder: (_, _, _) => _error(),
      );
    },
  );
}
