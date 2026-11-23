import '../../../core/errors/failures.dart';

enum AuthAttempt { login, signup }

/// 로그인·가입 실패를 화면 문구 한 줄로 바꾼다. 서버 안내가 충분한 오류는 그대로 둔다.
///
/// 서버는 같은 이메일로 1분 안에 5번 시도하면 그 1분이 끝날 때까지 맞는 비밀번호도
/// `429 RATE_LIMITED`로 막는다(2026-11-12 서버 #35, `login-rate-limiter.ts`·`signup-rate-limiter.ts`의
/// `WINDOW_MS`). 서버의 "요청이 너무 많아요"만으로는 무엇이 막혔는지 알 수 없어 시도 종류와 기다릴 시간을 알린다.
String authFailureMessage(Failure failure, AuthAttempt attempt) {
  if (failure.code == 'RATE_LIMITED') {
    return switch (attempt) {
      AuthAttempt.login => '로그인 시도가 너무 많아 잠시 막혔어요. 1분 뒤 다시 시도해 주세요.',
      AuthAttempt.signup => '가입 시도가 너무 많아 잠시 막혔어요. 1분 뒤 다시 시도해 주세요.',
    };
  }
  return failure.message;
}
