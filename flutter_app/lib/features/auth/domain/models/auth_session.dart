class AuthSession {
  final String userId;
  final String email;
  final String masthead;
  final String? profileImageUrl;
  final bool hasPublishedToday;
  final int issueCount;

  /// 미성년자는 같은 색 잠금이 없다(P01). 판별 방법은 미정이라 mock은 false.
  final bool isMinor;
  final String accessToken;
  final String refreshToken;

  const AuthSession({
    required this.userId,
    required this.email,
    required this.masthead,
    this.profileImageUrl,
    required this.hasPublishedToday,
    required this.issueCount,
    this.isMinor = false,
    required this.accessToken,
    required this.refreshToken,
  });

  AuthSession copyWith({
    String? userId,
    String? email,
    String? masthead,
    String? profileImageUrl,
    bool? hasPublishedToday,
    int? issueCount,
    bool? isMinor,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      masthead: masthead ?? this.masthead,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      hasPublishedToday: hasPublishedToday ?? this.hasPublishedToday,
      issueCount: issueCount ?? this.issueCount,
      isMinor: isMinor ?? this.isMinor,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['userId'] as String,
      email: json['email'] as String,
      masthead: json['masthead'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      hasPublishedToday: json['hasPublishedToday'] as bool? ?? false,
      issueCount: json['issueCount'] as int,
      isMinor: json['isMinor'] as bool? ?? false,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'masthead': masthead,
    'profileImageUrl': profileImageUrl,
    'hasPublishedToday': hasPublishedToday,
    'issueCount': issueCount,
    'isMinor': isMinor,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}
