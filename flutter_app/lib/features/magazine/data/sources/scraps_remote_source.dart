import '../../../../core/network/http_client.dart';
import '../../../issue/data/sources/issue_remote_source.dart';
import '../../../issue/domain/models/server_issue.dart';

/// 저장함(DEV-14) 서버 소스. `GET /me/scraps`는 지금 볼 수 있는 캔버스만 저장 최신순으로 준다.
/// 잠긴·삭제된·차단한 사람의 캔버스는 서버가 이미 뺐으므로 앱은 받은 것만 쓴다(P01).
/// 응답은 공개 표지 모양(IssuePublicDto)이라 반응 숫자가 없고, 모델에도 숫자 자리를 두지 않는다(P18).
class ScrapsRemoteSource {
  final AppHttpClient http;

  ScrapsRemoteSource(this.http);

  Future<ServerPage<ServerIssue>> page({String? cursor}) async {
    final data = await http.get('/me/scraps', queryParams: {'cursor': ?cursor});
    return ServerPage(
      (data['items'] as List)
          .map((v) => parseServerIssue(Map<String, dynamic>.from(v as Map)))
          .toList(),
      data['nextCursor'] as String?,
    );
  }
}
