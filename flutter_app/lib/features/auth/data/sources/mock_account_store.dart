import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/storage/password_digest.dart';

/// 시연(mock) 모드의 기기 안 계정 하나. 실제 인증이 아니다(서버 연결 후 DEV-05).
class MockAccount {
  final String userId;
  final String email;

  /// 개인 잡지 제호(P14). 창간 전에는 비어 있다.
  final String masthead;
  final bool isMinor;

  /// 이메일 계정만 있다. 소셜 시연 계정은 비밀번호가 없다.
  final String? salt;
  final String? digest;

  const MockAccount({
    required this.userId,
    required this.email,
    this.masthead = '',
    this.isMinor = false,
    this.salt,
    this.digest,
  });

  MockAccount copyWith({String? masthead}) => MockAccount(
    userId: userId,
    email: email,
    masthead: masthead ?? this.masthead,
    isMinor: isMinor,
    salt: salt,
    digest: digest,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'masthead': masthead,
    'isMinor': isMinor,
    'salt': salt,
    'digest': digest,
  };

  factory MockAccount.fromJson(Map<String, dynamic> json) => MockAccount(
    userId: json['userId'] as String,
    email: json['email'] as String,
    masthead: json['masthead'] as String? ?? '',
    isMinor: json['isMinor'] as bool? ?? false,
    salt: json['salt'] as String?,
    digest: json['digest'] as String?,
  );
}

/// 계정 목록을 두는 곳. 기기에서는 보안 저장소(Keychain·Keystore), 웹·테스트는 메모리.
abstract class MockAccountVault {
  Future<String?> read();
  Future<void> write(String value);
}

class SecureMockAccountVault implements MockAccountVault {
  static const _key = 'esel_mock_accounts';
  final FlutterSecureStorage _storage;

  const SecureMockAccountVault([this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

class InMemoryMockAccountVault implements MockAccountVault {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;
}

/// 이메일(소문자) → 계정.
class MockAccountStore {
  final MockAccountVault vault;
  Map<String, MockAccount>? _accounts;

  MockAccountStore([MockAccountVault? vault])
    : vault = vault ?? InMemoryMockAccountVault();

  static String normalize(String email) => email.trim().toLowerCase();

  Future<Map<String, MockAccount>> _load() async {
    final cached = _accounts;
    if (cached != null) return cached;
    final loaded = <String, MockAccount>{};
    final raw = await vault.read();
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        for (final item in list) {
          final account = MockAccount.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          loaded[normalize(account.email)] = account;
        }
      } on FormatException {
        // 깨진 기록은 버리고 새로 시작한다. 발행 기록(기기 보관함)은 그대로다.
      }
    }
    return _accounts = loaded;
  }

  Future<void> _save() async {
    final accounts = await _load();
    await vault.write(
      jsonEncode(accounts.values.map((a) => a.toJson()).toList()),
    );
  }

  Future<MockAccount?> find(String email) async =>
      (await _load())[normalize(email)];

  Future<MockAccount?> findById(String userId) async {
    for (final account in (await _load()).values) {
      if (account.userId == userId) return account;
    }
    return null;
  }

  Future<MockAccount?> findByMasthead(String masthead) async {
    for (final account in (await _load()).values) {
      if (account.masthead == masthead) return account;
    }
    return null;
  }

  /// 이메일 계정을 만든다. 같은 이메일이 있으면 null.
  Future<MockAccount?> createWithPassword({
    required String email,
    required String password,
    String masthead = '',
  }) async {
    final accounts = await _load();
    final key = normalize(email);
    if (accounts.containsKey(key)) return null;
    final salt = PasswordDigest.newSalt();
    final account = MockAccount(
      // 이전 시연 기록(기기 보관함)과 이어지도록 예전과 같은 id 형식을 쓴다.
      userId: 'mock_$key',
      email: email.trim(),
      masthead: masthead,
      salt: salt,
      digest: PasswordDigest.digest(password, salt),
    );
    accounts[key] = account;
    await _save();
    return account;
  }

  /// 소셜 시연 계정. 처음이면 제호 없이 만든다(→ 창간).
  Future<MockAccount> social(String provider) async {
    final accounts = await _load();
    final email = '$provider@mock.esel.local';
    final existing = accounts[email];
    if (existing != null) return existing;
    final account = MockAccount(userId: 'mock_$provider', email: email);
    accounts[email] = account;
    await _save();
    return account;
  }

  bool verify(MockAccount account, String password) {
    final salt = account.salt;
    final digest = account.digest;
    if (salt == null || digest == null) return false;
    return PasswordDigest.matches(password, salt, digest);
  }

  Future<MockAccount> update(MockAccount account) async {
    final accounts = await _load();
    accounts[normalize(account.email)] = account;
    await _save();
    return account;
  }

  Future<void> delete(String userId) async {
    final accounts = await _load();
    accounts.removeWhere((_, a) => a.userId == userId);
    await _save();
  }
}
