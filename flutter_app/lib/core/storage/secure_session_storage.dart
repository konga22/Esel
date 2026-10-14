import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'session_storage.dart';

class SecureSessionStorage implements SessionStorage {
  final FlutterSecureStorage _storage;
  const SecureSessionStorage([this._storage = const FlutterSecureStorage()]);
  static const _tokensKey = 'esel_session_tokens';
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) => _storage.write(
    key: _tokensKey,
    value: jsonEncode({
      'access_token': accessToken,
      'refresh_token': refreshToken,
    }),
  );
  @override
  Future<Map<String, String>?> getTokens() async {
    final value = await _storage.read(key: _tokensKey);
    if (value == null) return null;
    try {
      return Map<String, String>.from(jsonDecode(value) as Map);
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> clear() => _storage.delete(key: _tokensKey);
  @override
  Future<void> setString(String key, String value) =>
      _storage.write(key: 'esel_$key', value: value);
  @override
  Future<String?> getString(String key) => _storage.read(key: 'esel_$key');
}
