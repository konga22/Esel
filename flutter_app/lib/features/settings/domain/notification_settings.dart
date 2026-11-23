/// 내 알림 설정(DEV-19). 서버 `NotificationSettingsDto`와 같은 세 값이다.
///
/// 전체 알림을 끄면 하위 알림은 화면에서 꺼진 것으로 보이고 바꿀 수 없다. 하위 값 자체는 지우지 않아서
/// 전체를 다시 켜면 이전 선택이 돌아온다(서버도 세 값을 따로 저장한다).
/// 설정 저장까지만이다. 실제 알림 발송 서비스는 정하지 않았다.
class NotificationSettings {
  final bool enabled;
  final bool newIssue;
  final bool reactions;

  const NotificationSettings({
    required this.enabled,
    required this.newIssue,
    required this.reactions,
  });

  /// 서버가 아직 저장한 적 없는 계정에 돌려주는 기본값과 같다(모두 켜짐).
  const NotificationSettings.defaults()
    : enabled = true,
      newIssue = true,
      reactions = true;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        enabled: json['enabled'] as bool,
        newIssue: json['newIssue'] as bool,
        reactions: json['reactions'] as bool,
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'newIssue': newIssue,
    'reactions': reactions,
  };

  /// 화면에 보이는 하위 알림 값. 전체가 꺼져 있으면 꺼진 것으로 보인다.
  bool get showsNewIssue => enabled && newIssue;
  bool get showsReactions => enabled && reactions;

  NotificationSettings copyWith({
    bool? enabled,
    bool? newIssue,
    bool? reactions,
  }) => NotificationSettings(
    enabled: enabled ?? this.enabled,
    newIssue: newIssue ?? this.newIssue,
    reactions: reactions ?? this.reactions,
  );
}
