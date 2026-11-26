import '../../../core/network/http_client.dart';
import '../domain/report.dart';

/// 표지 신고 보내기(DEV-20). `ESEL_API_MODE`에 따라 [ReportsMemorySource] 또는
/// [ReportsRemoteSource]를 쓴다. 신고를 누가 어떤 기준으로 처리할지는 아직 정해지지 않아
/// 서버도 접수만 저장한다.
abstract interface class ReportsSource {
  Future<void> reportIssue(
    String issueId,
    ReportReason reason, {
    String details = '',
  });

  /// mock 모드처럼 서버에 보내지 않는 소스인지. 안내 문구를 정직하게 고르는 데 쓴다.
  bool get demo;
}

/// mock(시연) 모드. 서버가 없으므로 이 기기 메모리에만 담는다.
class ReportsMemorySource implements ReportsSource {
  final List<({String issueId, ReportReason reason, String details})> sent = [];

  @override
  bool get demo => true;

  @override
  Future<void> reportIssue(
    String issueId,
    ReportReason reason, {
    String details = '',
  }) async {
    sent.add((issueId: issueId, reason: reason, details: details));
  }
}

/// 서버 모드. 경로·오류는 `server/api-contract.json`의 moderation 묶음을 따른다.
class ReportsRemoteSource implements ReportsSource {
  final AppHttpClient http;

  ReportsRemoteSource(this.http);

  @override
  bool get demo => false;

  @override
  Future<void> reportIssue(
    String issueId,
    ReportReason reason, {
    String details = '',
  }) async {
    final trimmed = details.trim();
    await http.post(
      '/issues/${Uri.encodeComponent(issueId)}/reports',
      body: {
        'reason': reason.apiValue,
        if (trimmed.isNotEmpty) 'details': trimmed,
      },
    );
  }
}
