enum TwinStage {
  invited,           // T2 초대 발송
  colorSelection,    // T3 나의 색 고르기
  readyToPost,       // T4 나의 표지 준비
  waitingForPartner, // T5 상대 게시 기다림 (내 것만 게시됨)
  revealed,          // T6 두 표지 공개 (양측 게시 완료)
  visibilityChoice,  // T7 공개 범위 선택
  consentWaiting,    // T8 공동 공개 동의 대기
  published,         // T10 공동 발행 완료
  privateOnly,       // T8private 둘만의 기록
  soloOnly,          // T8solo 내 표지만 공개
}

enum TwinVisibility {
  privateRecord, // 둘만의 기록으로
  soloPublic,    // 내 표지만 공개
  jointPublic,   // 공동 공개
}

/// P08, P09, P10 트윈 규칙
class TwinRule {
  static bool canRevealPartnerPhoto({
    required bool hasUserPosted,
    required bool hasPartnerPosted,
  }) {
    return hasUserPosted && hasPartnerPosted;
  }

  static bool canPublishJointIssue({
    required TwinVisibility visibility,
    required bool hasUserConsented,
    required bool hasPartnerConsented,
  }) {
    if (visibility != TwinVisibility.jointPublic) {
      return true; // private 또는 solo는 즉시 완료 가능
    }
    return hasUserConsented && hasPartnerConsented;
  }

  // P09: 트윈 게시는 개인 호수·기록·같은 색 잠금과 독립이다. 트윈 상태는 기기 보관함과
  // TodayController에 닿지 않는다(twin_test가 확인).
}
