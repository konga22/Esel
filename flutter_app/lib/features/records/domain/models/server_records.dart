import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_date.dart';

class ServerDayRecord {
  final ServiceDate date;
  final EselPaint color;
  final bool restored;
  final String? issueId;
  const ServerDayRecord({
    required this.date,
    required this.color,
    required this.restored,
    required this.issueId,
  });
}

class ServerMonthRecords {
  final String month;
  final int remaining;
  final List<ServerDayRecord> days;
  const ServerMonthRecords(this.month, this.remaining, this.days);
}
