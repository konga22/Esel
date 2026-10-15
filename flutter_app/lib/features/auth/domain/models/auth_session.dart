class AuthSession {
  final String userId;
  final String email;
  final String masthead;
  final String? profileImageUrl;
  final bool hasPublishedToday;
  final int issueCount;
  final String accessToken;
  final String refreshToken;

  const AuthSession({
    required this.userId,
    required this.email,
    required this.masthead,
    this.profileImageUrl,
    required this.hasPublishedToday,
    required this.issueCount,
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
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}
