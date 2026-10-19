import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import '../config/app_config.dart';
import '../errors/failures.dart';
import '../storage/session_storage.dart';

abstract class AppHttpClient {
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  });
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
  });
}

/// JSON 호출과 같은 인증·갱신·오류 처리를 사용하는 바이너리 통신.
abstract interface class BinaryHttpClient {
  Future<Uint8List> getBytes(String path, {Map<String, String>? queryParams});
  Future<void> putBytes(
    String path,
    Uint8List bytes, {
    required String contentType,
  });
}

class StandardHttpClient implements AppHttpClient, BinaryHttpClient {
  final AppConfig config;
  final SessionStorage storage;
  Future<void>? _refreshing;

  /// 연결 제한(10초)·응답 무진행 제한(15초)은 유지한다.
  /// 업로드 본문 전송은 최소 30초 + 32KiB/s 기준 크기별 예산을 둔다.
  static Duration uploadTimeout(int bytes) => Duration(
    seconds: 30 + (bytes.clamp(0, 15 * 1024 * 1024) / (32 * 1024)).ceil(),
  );
  StandardHttpClient({required this.config, required this.storage});

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) => _send('GET', path, queryParams: queryParams);
  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) => _send('POST', path, body: body);
  @override
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      _send('PUT', path, body: body);
  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) => _send('PATCH', path, body: body);
  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
  }) => _send('DELETE', path, body: body);

  /// access 토큰을 붙이는 요청인지. 가입·로그인·토큰 갱신(`/auth/*`)은 토큰 없이 보낸다.
  /// 서버는 토큰이 붙어 있으면 공개 주소에서도 검사하므로, 만료된 토큰을 붙이면 갱신이
  /// `TOKEN_EXPIRED`로 실패해 로그아웃된다(#26 리뷰). 로그아웃만 지금 세션 토큰이 필요하다.
  static bool sendsAccessToken(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return normalized == '/auth/logout' || !normalized.startsWith('/auth/');
  }

  @override
  Future<Uint8List> getBytes(String path, {Map<String, String>? queryParams}) =>
      _send<Uint8List>('GET', path, queryParams: queryParams, binary: true);

  @override
  Future<void> putBytes(
    String path,
    Uint8List bytes, {
    required String contentType,
  }) async {
    await _send<Map<String, dynamic>>(
      'PUT',
      path,
      rawBody: bytes,
      contentType: contentType,
    );
  }

  Future<T> _send<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool retry = true,
    Uint8List? rawBody,
    String? contentType,
    bool binary = false,
  }) async {
    final client = io.HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final base = config.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
      final uri = Uri.parse(
        '$base${path.startsWith('/') ? path : '/$path'}',
      ).replace(queryParameters: queryParams);
      final request = await client.openUrl(method, uri);
      request.followRedirects = false;
      request.headers.contentType = contentType == null
          ? io.ContentType.json
          : io.ContentType.parse(contentType);
      request.headers.set(
        io.HttpHeaders.acceptHeader,
        binary ? 'image/png, image/jpeg' : 'application/json',
      );
      final tokens = sendsAccessToken(path) ? await storage.getTokens() : null;
      if (tokens != null) {
        request.headers.set(
          io.HttpHeaders.authorizationHeader,
          'Bearer ${tokens['access_token']}',
        );
      }
      if (rawBody != null) {
        request.contentLength = rawBody.length;
        request.add(rawBody);
      } else if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(
        rawBody == null
            ? const Duration(seconds: 15)
            : uploadTimeout(rawBody.length),
      );
      final received = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 15))) {
        if (received.length + chunk.length > 15 * 1024 * 1024) {
          throw const NetworkFailure('사진 응답이 너무 커요.', code: 'MEDIA_TOO_LARGE');
        }
        received.add(chunk);
      }
      final bytes = received.takeBytes();
      final success = response.statusCode >= 200 && response.statusCode < 300;
      if (success && binary) return bytes as T;
      final text = utf8.decode(bytes);
      final json = text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>;
      if (success) return json as T;
      final error = json['error'] is Map
          ? Map<String, dynamic>.from(json['error'] as Map)
          : <String, dynamic>{};
      final code = error['code'] as String? ?? 'SERVER_ERROR';
      final message = [
        error['message'] ?? '요청을 처리하지 못했어요.',
        error['hint'],
      ].whereType<String>().join(' ');
      if (response.statusCode == 401 &&
          code == 'TOKEN_EXPIRED' &&
          retry &&
          sendsAccessToken(path)) {
        _refreshing ??= _refresh();
        try {
          await _refreshing;
        } finally {
          _refreshing = null;
        }
        // try 안에서는 기다린 뒤 돌려준다. 그래야 다시 보낸 요청의 오류도 아래 catch가
        // 받고, finally의 client.close가 응답을 받기 전에 실행되지 않는다.
        return await _send<T>(
          method,
          path,
          body: body,
          queryParams: queryParams,
          retry: false,
          rawBody: rawBody,
          contentType: contentType,
          binary: binary,
        );
      }
      if (response.statusCode == 401) throw AuthFailure(message, code: code);
      if (response.statusCode == 404) {
        throw NotFoundFailure(message, code: code);
      }
      throw RuleFailure(message, code: code);
    } on Failure {
      rethrow;
    } on TimeoutException {
      throw const NetworkFailure(
        '서버 응답이 늦어지고 있어요. 연결 상태를 확인해 주세요.',
        code: 'TIMEOUT',
      );
    } on io.SocketException {
      throw const NetworkFailure(
        '서버에 연결할 수 없어요. 인터넷 연결을 확인하고 잠시 뒤 다시 시도해 주세요.',
        code: 'OFFLINE',
      );
    } on FormatException {
      throw const NetworkFailure(
        '서버 응답 형식이 올바르지 않아요.',
        code: 'INVALID_RESPONSE',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _refresh() async {
    final tokens = await storage.getTokens();
    if (tokens == null) {
      throw const AuthFailure('다시 로그인해 주세요.', code: 'AUTH_REQUIRED');
    }
    try {
      final session = await _send<Map<String, dynamic>>(
        'POST',
        '/auth/refresh',
        body: {'refreshToken': tokens['refresh_token']},
        retry: false,
      );
      await storage.saveTokens(
        accessToken: session['accessToken'] as String,
        refreshToken: session['refreshToken'] as String,
      );
    } on AuthFailure {
      await storage.clear();
      rethrow;
    }
  }
}
