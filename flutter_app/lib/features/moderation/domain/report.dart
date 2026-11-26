import '../../../core/errors/failures.dart';

/// 신고 사유(DEV-20). 서버 `CreateReportDto.reason`과 같은 값이다.
enum ReportReason {
  spam('spam', '스팸·광고'),
  harassment('harassment', '괴롭힘·혐오 표현'),
  inappropriate('inappropriate', '부적절한 사진·내용'),
  other('other', '기타');

  final String apiValue;
  final String label;

  const ReportReason(this.apiValue, this.label);
}

/// 서버 `CreateReportDto.details` 최대 길이.
const reportDetailsMaxLength = 500;

/// 신고 보내기 실패 문구.
String reportFailureMessage(Object failure) {
  if (failure is Failure) {
    switch (failure.code) {
      case 'RATE_LIMITED':
        // 서버는 한 사람이 1분에 5건까지 받는다(report-rate-limiter.ts).
        return '신고가 너무 많아요. 1분 뒤 다시 시도해 주세요.';
      case 'NOT_FOUND':
        return '볼 수 없는 캔버스라 신고할 수 없어요.';
      case 'VALIDATION':
        return '신고 내용을 확인해 주세요. 내용은 $reportDetailsMaxLength자까지 쓸 수 있어요.';
    }
    return failure.message;
  }
  return '신고를 보내지 못했어요. 다시 시도해 주세요.';
}
