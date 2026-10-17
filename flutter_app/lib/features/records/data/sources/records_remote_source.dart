import '../../../../core/design/tokens.g.dart';
import '../../../../core/network/http_client.dart';
import '../../../../core/time/service_date.dart';
import '../../domain/models/server_records.dart';

class RecordsRemoteSource {
  final AppHttpClient http;
  RecordsRemoteSource(this.http);
  Future<ServerMonthRecords> month(String key) async {
    final data = await http.get('/me/records', queryParams: {'month': key});
    return ServerMonthRecords(
      data['month'] as String,
      data['remainingRestores'] as int,
      (data['days'] as List).map((v) {
        final day = v as Map;
        return ServerDayRecord(
          date:
              ServiceDate.tryParse(day['serviceDate'] as String) ??
              (throw const FormatException('기록 날짜가 올바르지 않아요.')),
          color: EselPaint.values.byName((day['color'] as Map)['id'] as String),
          restored: day['kind'] == 'RESTORED',
          issueId: day['issueId'] as String?,
        );
      }).toList(),
    );
  }

  Future<void> restore(ServiceDate date, EselPaint color) async {
    await http.post(
      '/me/records/${date.key}/restore',
      body: {'colorId': color.name},
    );
  }
}
