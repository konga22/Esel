import '../../../core/errors/failures.dart';

/// `POST /issues`가 연결할 수 있는 사진이 없다고 답한 경우(409).
/// 서버는 호에 연결되지 않고 24시간이 지난 사진을 지우므로(2026-11-12 서버 #35), 그 사진 ID로는
/// 다시 보내도 같은 답이 온다. 앱은 올리기마다 사진을 새로 올리므로, 사용자가 다시 올리기를 누르면 된다.
const mediaNotReadyCode = 'MEDIA_NOT_READY';

/// 사진을 새로 올리면 해결되는 발행 실패인지. 화면은 이때 "사진 다시 올리기"를 보인다.
/// 자동으로 다시 보내지 않는다(사용자가 누를 때만).
bool canRetryWithNewPhoto(Failure failure) => failure.code == mediaNotReadyCode;

/// 서버의 "업로드를 마친 뒤 다시 시도해 주세요"는 사용자가 할 수 있는 일이 아니라서 바꾼다.
/// 코드는 보존해 재조회·복구 판단과 화면이 같은 기준을 쓴다.
Failure explainPublishFailure(Failure failure) => canRetryWithNewPhoto(failure)
    ? const RuleFailure(
        '사진이 서버에 준비되지 않았어요. 사진 다시 올리기를 누르면 사진을 새로 올려요.',
        code: mediaNotReadyCode,
      )
    : failure;
