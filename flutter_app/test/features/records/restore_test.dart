import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/records/domain/rules/restore_rule.dart';

void main() {
  group('DEV-02 P06, P07 Restore Rule Tests', () {
    final now = DateTime(2026, 9, 6);

    test('permits restoring past blank date in current month when under 2 restores', () {
      final can = RestoreRule.canRestoreDate(
        targetDate: DateTime(2026, 9, 3),
        currentDate: now,
        isAlreadyRecorded: false,
        usedRestoreCountThisMonth: 0,
      );
      expect(can, isTrue);
    });

    test('rejects 3rd restore attempt when monthly limit is reached', () {
      final can = RestoreRule.canRestoreDate(
        targetDate: DateTime(2026, 9, 3),
        currentDate: now,
        isAlreadyRecorded: false,
        usedRestoreCountThisMonth: 2,
      );
      expect(can, isFalse);
    });

    test('rejects restoring already recorded dates', () {
      final can = RestoreRule.canRestoreDate(
        targetDate: DateTime(2026, 9, 2),
        currentDate: now,
        isAlreadyRecorded: true,
        usedRestoreCountThisMonth: 0,
      );
      expect(can, isFalse);
    });

    test('rejects today or future dates', () {
      expect(
        RestoreRule.canRestoreDate(
          targetDate: DateTime(2026, 9, 6),
          currentDate: now,
          isAlreadyRecorded: false,
          usedRestoreCountThisMonth: 0,
        ),
        isFalse,
      );
      expect(
        RestoreRule.canRestoreDate(
          targetDate: DateTime(2026, 9, 10),
          currentDate: now,
          isAlreadyRecorded: false,
          usedRestoreCountThisMonth: 0,
        ),
        isFalse,
      );
    });
  });
}
