import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';

void main() {
  late HttpServer server;
  late StandardHttpClient http;
  late InMemorySessionStorage storage;
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    storage = InMemorySessionStorage();
    await storage.saveTokens(accessToken: 'old', refreshToken: 'refresh');
    http = StandardHttpClient(
      config: AppConfig(apiBaseUrl: 'http://127.0.0.1:${server.port}/api'),
      storage: storage,
    );
  });
  tearDown(() => server.close(force: true));
  test('바이너리도 만료 토큰을 갱신하고 재요청하며 JSON 오류를 구분한다', () async {
    var refreshes = 0;
    server.listen((req) async {
      if (req.uri.path == '/api/auth/refresh') {
        expect(req.headers.value('authorization'), isNull);
        await req.drain<void>();
        refreshes++;
        req.response.write(
          jsonEncode({'accessToken': 'new', 'refreshToken': 'next'}),
        );
      } else if (req.headers.value('authorization') == 'Bearer old') {
        req.response.statusCode = 401;
        req.response.write(
          jsonEncode({
            'error': {'code': 'TOKEN_EXPIRED', 'message': 'expired'},
          }),
        );
      } else if (req.uri.path.endsWith('/missing')) {
        req.response.statusCode = 404;
        req.response.write(
          jsonEncode({
            'error': {'code': 'MEDIA_NOT_FOUND', 'message': 'missing'},
          }),
        );
      } else {
        expect(req.headers.value('authorization'), 'Bearer new');
        req.response.headers.contentType = ContentType('image', 'png');
        req.response.add([137, 80, 78, 71]);
      }
      await req.response.close();
    });
    expect(await http.getBytes('/media/test'), [137, 80, 78, 71]);
    expect(refreshes, 1);
    await expectLater(
      http.getBytes('/media/missing'),
      throwsA(
        isA<NotFoundFailure>().having((e) => e.code, 'code', 'MEDIA_NOT_FOUND'),
      ),
    );
  });
  test('PUT은 JSON 인코딩 없이 사진 바이트와 MIME을 보내고 204를 처리한다', () async {
    server.listen((req) async {
      expect(req.method, 'PUT');
      expect(req.headers.contentType!.mimeType, 'image/png');
      expect(
        await req.fold<List<int>>([], (list, chunk) => list..addAll(chunk)),
        [0, 128, 255],
      );
      req.response.statusCode = 204;
      await req.response.close();
    });
    await http.putBytes(
      '/media/test/file',
      Uint8List.fromList([0, 128, 255]),
      contentType: 'image/png',
    );
  });
}
