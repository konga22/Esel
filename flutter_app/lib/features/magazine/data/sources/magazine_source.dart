import '../../../stand/domain/rules/same_color_rule.dart';
import '../../domain/models/magazine_models.dart';

/// 스케치북을 받는 곳(DEV-03). 없는 잡지는 null.
abstract class MagazineSource {
  /// [masthead]는 아직 호가 없는 스케치북의 이름을 채우는 데만 쓴다.
  Future<MagazineProfile?> magazine(
    String ownerId, {
    required SameColorViewer viewer,
    String? viewerId,
    String? masthead,
    String? cursor,
  });
}
