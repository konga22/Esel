import 'dart:async';
import 'dart:convert';
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
  Future<Map<String, dynamic>> delete(String path);
}

class StandardHttpClient implements AppHttpClient {
  final AppConfig config;
  final SessionStorage storage;
  Future<void>? _refreshing;
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
  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool retry = true,
  }) async {
    final client = io.HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final base = config.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
      final uri = Uri.parse(
        '$base${path.startsWith('/') ? path : '/$path'}',
      ).replace(queryParameters: queryParams);
      final request = await client.openUrl(method, uri);
      request.headers.contentType = io.ContentType.json;
      request.headers.set(io.HttpHeaders.acceptHeader, 'application/json');
      final tokens = await storage.getTokens();
      if (tokens != null) {
        request.headers.set(
          io.HttpHeaders.authorizationHeader,
          'Bearer ${tokens['access_token']}',
        );
      }
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final text = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));
      final json = text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) return json;
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
          !path.startsWith('/auth/')) {
        _refreshing ??= _refresh();
        try {
          await _refreshing;
        } finally {
          _refreshing = null;
        }
        return _send(
          method,
          path,
          body: body,
          queryParams: queryParams,
          retry: false,
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
      final session = await _send(
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
