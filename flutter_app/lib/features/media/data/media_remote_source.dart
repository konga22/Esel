import 'package:flutter/foundation.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/http_client.dart';

/// 서버 미디어. 사진은 메모리에서만 캐시하며 계정이 바뀌면 이전 응답을 사용하지 않는다.
class MediaRemoteSource extends ChangeNotifier {
  final AppHttpClient http;
  MediaRemoteSource(this.http);
  String? _owner;
  String? get ownerId => _owner;
  int generation = 0;
  final _photos = <String, Future<Uint8List>>{};
  static const maxBytes = 15 * 1024 * 1024;
  void bindOwner(String? owner) {
    if (_owner == owner) return;
    _owner = owner;
    generation++;
    _photos.clear();
    notifyListeners();
  }

  BinaryHttpClient get _binary {
    final client = http;
    if (client is BinaryHttpClient) return client as BinaryHttpClient;
    throw const NotImplementedFailure('사진 통신을 준비 중이에요.');
  }

  Future<Uint8List> photo(
    String id, {
    bool thumbnail = false,
    bool retry = false,
  }) {
    final key = '$generation|$id|$thumbnail';
    if (retry) _photos.remove(key);
    if (_photos.length >= 24 && !_photos.containsKey(key)) {
      _photos.remove(_photos.keys.first);
    }
    return _photos.putIfAbsent(key, () async {
      final version = generation;
      try {
        final bytes = await _binary.getBytes(
          '/media/${Uri.encodeComponent(id)}',
          queryParams: {'size': thumbnail ? 'thumb' : 'original'},
        );
        if (version != generation) throw const AuthFailure('계정이 변경됐어요.');
        return bytes;
      } catch (_) {
        _photos.remove(key);
        rethrow;
      }
    });
  }

  /// 올리기 재시도/이어 올리기는 하지 않는다. 준비→PUT→완료 응답을 순서대로 확인한다.
  Future<String> upload(
    Uint8List bytes, {
    String mimeType = 'image/png',
  }) async {
    if (bytes.isEmpty ||
        bytes.length > maxBytes ||
        !{'image/png', 'image/jpeg'}.contains(mimeType)) {
      throw const RuleFailure('PNG·JPEG 사진을 15MB 이하로 준비해 주세요.');
    }
    if (_owner == null) throw const AuthFailure('사진을 올리려면 로그인해 주세요.');
    final version = generation;
    void check() {
      if (version != generation) {
        throw const AuthFailure('계정이 변경됐어요. 다시 시도해 주세요.');
      }
    }

    final prepared = await http.post(
      '/media',
      body: {'mimeType': mimeType, 'sizeBytes': bytes.length},
    );
    check();
    final id = prepared['id'] as String;
    final path = '/media/${Uri.encodeComponent(id)}/file';
    // 서버가 발급하는 API 내부 경로만 허용한다. 외부 주소에 Bearer를 보내지 않는다.
    if (prepared['uploadUrl'] != '/api$path' ||
        bytes.length > (prepared['maxSizeBytes'] as int) ||
        !(prepared['allowedMimeTypes'] as List).contains(mimeType)) {
      throw const RuleFailure('사진 업로드 안내를 확인하지 못했어요.');
    }
    await _binary.putBytes(path, bytes, contentType: mimeType);
    check();
    final completed = await http.post(
      '/media/${Uri.encodeComponent(id)}/complete',
    );
    check();
    if (completed['id'] != id || completed['status'] != 'READY') {
      throw const RuleFailure('사진 업로드가 완료되지 않았어요.');
    }
    return id;
  }
}
