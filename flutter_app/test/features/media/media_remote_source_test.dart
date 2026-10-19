import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/features/media/data/media_remote_source.dart';

class MediaHttp implements AppHttpClient, BinaryHttpClient {
  final calls = <String>[];
  Uint8List? received;
  bool external = false, ready = true, failRead = false;
  Completer<Uint8List>? reading;
  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    calls.add('POST $path');
    if (path == '/media') {
      expect(body, {'mimeType': 'image/png', 'sizeBytes': 3});
      return {
        'id': 'test-media',
        'uploadUrl': external
            ? 'https://outside.invalid/file'
            : '/api/media/test-media/file',
        'maxSizeBytes': MediaRemoteSource.maxBytes,
        'allowedMimeTypes': ['image/png', 'image/jpeg'],
      };
    }
    return {'id': 'test-media', 'status': ready ? 'READY' : 'PENDING'};
  }

  @override
  Future<void> putBytes(
    String path,
    Uint8List bytes, {
    required String contentType,
  }) async {
    calls.add('PUT $path');
    received = bytes;
    expect(contentType, 'image/png');
  }

  @override
  Future<Uint8List> getBytes(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    calls.add('GET $path?size=${queryParams!['size']}');
    if (failRead) throw const NotFoundFailure('사진 없음');
    return reading?.future ?? Future.value(Uint8List.fromList([1, 2, 3]));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('준비 → 동일 바이트 PUT → READY 확인 순서로 사진을 올린다', () async {
    final http = MediaHttp();
    final source = MediaRemoteSource(http)..bindOwner('owner');
    expect(await source.upload(Uint8List.fromList([1, 2, 3])), 'test-media');
    expect(http.calls, [
      'POST /media',
      'PUT /media/test-media/file',
      'POST /media/test-media/complete',
    ]);
    expect(http.received, [1, 2, 3]);
  });
  test('외부 업로드 주소에는 PUT을 보내지 않고 미완료 사진을 성공으로 반환하지 않는다', () async {
    final http = MediaHttp()..external = true;
    final source = MediaRemoteSource(http)..bindOwner('owner');
    await expectLater(
      source.upload(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<RuleFailure>()),
    );
    expect(http.calls, ['POST /media']);
    http.external = false;
    http.ready = false;
    await expectLater(
      source.upload(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<RuleFailure>()),
    );
  });
  test('목록은 thumb, 상세는 original, 404 후 재요청은 네트워크로 다시 읽는다', () async {
    final http = MediaHttp();
    final source = MediaRemoteSource(http);
    await source.photo('test-media', thumbnail: true);
    await source.photo('test-media');
    expect(http.calls, [
      'GET /media/test-media?size=thumb',
      'GET /media/test-media?size=original',
    ]);
    http.failRead = true;
    await expectLater(source.photo('hidden'), throwsA(isA<NotFoundFailure>()));
    http.failRead = false;
    await source.photo('hidden');
    expect(http.calls.where((v) => v.contains('/hidden')), hasLength(2));
  });
  test('계정 변경 중 응답은 버리고 새 계정에서 다시 요청한다', () async {
    final http = MediaHttp()..reading = Completer<Uint8List>();
    final source = MediaRemoteSource(http)..bindOwner('a');
    final request = source.photo('test-media');
    final assertion = expectLater(request, throwsA(isA<AuthFailure>()));
    source.bindOwner('b');
    http.reading!.complete(Uint8List.fromList([1]));
    await assertion;
    http.reading = null;
    await source.photo('test-media');
    expect(http.calls, hasLength(2));
  });
  test('로그아웃 상태에서는 사진 업로드 요청을 보내지 않는다', () async {
    final http = MediaHttp();
    final source = MediaRemoteSource(http);
    await expectLater(
      source.upload(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<AuthFailure>()),
    );
    expect(http.calls, isEmpty);
  });
}
