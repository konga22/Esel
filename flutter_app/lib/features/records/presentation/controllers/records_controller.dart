import 'package:flutter/foundation.dart';
import '../../../../core/design/tokens.g.dart';
import '../../domain/rules/restore_rule.dart';

enum RecordType {
  published, // 사진으로 올린 날
  restored, // 테두리 링으로 복원한 날
  empty, // 비어있는 날
  future, // 미래 날짜
}

class DayRecord {
  final int day;
  final RecordType type;
  final EselPaint? color;

  const DayRecord({required this.day, required this.type, this.color});

  DayRecord copyWith({RecordType? type, EselPaint? color}) {
    return DayRecord(
      day: day,
      type: type ?? this.type,
      color: color ?? this.color,
    );
  }
}

class RecordsController extends ChangeNotifier {
  final DateTime _today = DateTime(2026, 9, 6);
  int _usedRestores = 0;

  int get usedRestores => _usedRestores;

  /// 화면 머리의 달(`2026. 9`). 기록 화면은 아직 시연 범위 밖이라 예시 달을 쓴다.
  String get monthLabel => '${_today.year}. ${_today.month}';
  int get remainingRestores =>
      (RestoreRule.maxMonthlyRestores - _usedRestores).clamp(0, 2);

  final Map<int, DayRecord> _daysMap = {};

  RecordsController() {
    _initCalendar();
  }

  void _initCalendar() {
    for (int day = 1; day <= 30; day++) {
      if (day > _today.day) {
        _daysMap[day] = DayRecord(day: day, type: RecordType.future);
      } else if (day == 1 || day == 2 || day == 5 || day == 6) {
        // 과거 올린 날
        _daysMap[day] = DayRecord(
          day: day,
          type: RecordType.published,
          color: day % 2 == 0 ? EselPaint.powder : EselPaint.sage,
        );
      } else {
        // 빈 날 (복원 대상: 3일, 4일)
        _daysMap[day] = DayRecord(day: day, type: RecordType.empty);
      }
    }
  }

  DayRecord getRecord(int day) {
    return _daysMap[day] ?? DayRecord(day: day, type: RecordType.empty);
  }

  bool canRestore(int day) {
    final record = getRecord(day);
    return RestoreRule.canRestoreDate(
      targetDate: DateTime(2026, 9, day),
      currentDate: _today,
      isAlreadyRecorded: record.type != RecordType.empty,
      usedRestoreCountThisMonth: _usedRestores,
    );
  }

  String? getDenialReason(int day) {
    final record = getRecord(day);
    return RestoreRule.getRestoreDenialReason(
      targetDate: DateTime(2026, 9, day),
      currentDate: _today,
      isAlreadyRecorded: record.type != RecordType.empty,
      usedRestoreCountThisMonth: _usedRestores,
    );
  }

  bool restoreDay(int day, EselPaint color) {
    if (!canRestore(day)) return false;

    _daysMap[day] = DayRecord(
      day: day,
      type: RecordType.restored,
      color: color,
    );
    _usedRestores++;
    notifyListeners();
    return true;
  }
}
