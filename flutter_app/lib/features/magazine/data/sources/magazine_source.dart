import '../../../stand/domain/rules/same_color_rule.dart';
import '../../domain/models/magazine_models.dart';

/// 서가를 받는 곳(DEV-03). 없는 잡지는 null.
abstract class MagazineSource {
  /// [masthead]는 아직 호가 없는 내 잡지의 이름을 채우는 데만 쓴다.
  Future<MagazineProfile?> magazine(
    String ownerId, {
    required SameColorViewer viewer,
    String? viewerId,
    String? masthead,
  });
}
