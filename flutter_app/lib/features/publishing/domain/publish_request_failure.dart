import '../../../core/errors/failures.dart';

/// POST가 시작된 뒤 응답을 확인하지 못했다. 재전송 전에 서버 저장 여부를 조회한다.
class PublishRequestFailure extends Failure {
  final String mediaId;
  final Object cause;
  PublishRequestFailure(this.mediaId, this.cause)
    : super(
        cause is Failure ? cause.message : '올리기 결과를 확인하지 못했어요.',
        code: cause is Failure ? cause.code : 'PUBLISH_RESULT_UNKNOWN',
      );
}
