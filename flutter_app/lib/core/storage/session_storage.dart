abstract class SessionStorage {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<Map<String, String>?> getTokens();
  Future<void> clear();
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
}

class InMemorySessionStorage implements SessionStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _data['access_token'] = accessToken;
    _data['refresh_token'] = refreshToken;
  }

  @override
  Future<Map<String, String>?> getTokens() async {
    final access = _data['access_token'];
    final refresh = _data['refresh_token'];
    if (access == null || refresh == null) return null;
    return {'access_token': access, 'refresh_token': refresh};
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return _data[key];
  }
}
