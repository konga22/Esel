import '../../../../core/errors/failures.dart';
import '../../../../core/network/http_client.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../../domain/models/magazine_models.dart';
import 'magazine_source.dart';

/// 서버 서가. 아직 서버가 없어 미구현이다.
/// 초안 API: `GET /api/magazines/{masthead}`(DEV-13), 내 잡지 `GET /api/me/magazine`(DEV-14).
class MagazineRemoteSource implements MagazineSource {
  final AppHttpClient http;

  MagazineRemoteSource(this.http);

  @override
  Future<MagazineProfile?> magazine(
    String ownerId, {
    required SameColorViewer viewer,
    String? viewerId,
    String? masthead,
  }) async {
    throw const NotImplementedFailure('서버 서가는 아직 연결하지 않았어요.');
  }
}
