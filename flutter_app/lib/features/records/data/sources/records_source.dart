import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_date.dart';
import '../../../../core/time/service_clock.dart';
import '../../../drafts/data/local_library.dart';
import '../../../today/domain/rules/daily_candidates.dart';
import '../../domain/models/server_records.dart';

abstract class RecordsSource {
  Future<ServiceDate> today();
  Future<ServerMonthRecords> month(String key);
  Future<void> restore(ServiceDate date, EselPaint color);
}

class LocalRecordsSource implements RecordsSource {
  final LocalLibrary? Function() library;
  final String? Function() owner;
  final ServiceClock clock;
  LocalRecordsSource(this.library, this.owner, this.clock);
  @override
  Future<ServiceDate> today() async => clock.today;
  @override
  Future<ServerMonthRecords> month(String key) async {
    final id = owner(), lib = library();
    if (id == null || lib == null) throw const FormatException('로그인이 필요해요.');
    final restored = lib
        .restoredColorsFor(id)
        .entries
        .where((v) => v.key.startsWith(key))
        .toList();
    return ServerMonthRecords(key, (2 - restored.length).clamp(0, 2), [
      for (final issue
          in lib
              .issuesFor(id)
              .where((v) => v.publishedOn?.startsWith(key) == true))
        ServerDayRecord(
          date: ServiceDate.tryParse(issue.publishedOn)!,
          color: issue.color,
          restored: false,
          issueId: issue.id,
        ),
      for (final day in restored)
        ServerDayRecord(
          date: ServiceDate.tryParse(day.key)!,
          color: EselPaint.values.byName(day.value),
          restored: true,
          issueId: null,
        ),
    ]);
  }

  @override
  Future<void> restore(ServiceDate date, EselPaint color) async {
    if (date.year != clock.today.year ||
        date.month != clock.today.month ||
        !date.isBefore(clock.today)) {
      throw const FormatException('이번 달 지난 빈 날짜만 복원할 수 있어요.');
    }
    if (!DailyCandidates.forDate(date).contains(color)) {
      throw const FormatException('그날 후보에 없는 색이에요.');
    }
    await library()!.restoreColor(owner()!, date, color.name);
  }
}
