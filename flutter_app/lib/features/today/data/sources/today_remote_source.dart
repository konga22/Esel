import '../../../../core/design/tokens.g.dart';
import '../../../../core/network/http_client.dart';
import '../../../../core/time/service_date.dart';
import '../../domain/models/server_today.dart';

class TodayRemoteSource {
  final AppHttpClient http;
  TodayRemoteSource(this.http);
  Future<ServerToday> today() async => _parse(await http.get('/today'));
  Future<ServerToday> choose(EselPaint color) async =>
      _parse(await http.put('/today/choice', body: {'colorId': color.name}));
  ServerToday _parse(Map<String, dynamic> data) {
    final candidates = (data['candidates'] as List)
        .map((v) => EselPaint.values.byName((v as Map)['id'] as String))
        .toList();
    if (candidates.length != 3 || candidates.toSet().length != 3) {
      throw const FormatException('오늘 후보 3색을 확인하지 못했어요.');
    }
    return ServerToday(
      date:
          ServiceDate.tryParse(data['serviceDate'] as String) ??
          (throw const FormatException('서버 날짜를 확인하지 못했어요.')),
      candidates: List.unmodifiable(candidates),
      selected: data['selectedColorId'] == null
          ? null
          : EselPaint.values.byName(data['selectedColorId'] as String),
      published: data['hasPublishedToday'] as bool,
    );
  }
}
