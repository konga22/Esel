import '../../../../core/design/tokens.g.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/http_client.dart';
import '../../../../core/time/service_date.dart';
import '../../domain/models/stand_shelf.dart';
import '../../domain/rules/same_color_rule.dart';
import 'stand_source.dart';

/// 서버 가판대. 아직 서버가 없어 미구현이다.
/// 초안 API: `GET /api/stand?date=&color=` → `{access, covers, hiddenCount}`(DEV-12).
class StandRemoteSource implements StandSource {
  final AppHttpClient http;

  StandRemoteSource(this.http);

  @override
  Future<StandShelf> shelf({
    required SameColorViewer viewer,
    String? viewerId,
    EselPaint? color,
  }) async {
    throw const NotImplementedFailure('서버 가판대는 아직 연결하지 않았어요.');
  }

  @override
  Future<int> sameColorCount(ServiceDate date, EselPaint color) async {
    throw const NotImplementedFailure('서버 가판대는 아직 연결하지 않았어요.');
  }
}
