import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/today/domain/rules/daily_candidates.dart';

void main() {
  group('DEV-07 P17 오늘의 색 후보 3가지', () {
    final days = [
      for (var i = 0; i < 120; i++) const ServiceDate(2026, 10, 1).addDays(i),
    ];

    test('날짜마다 12색 중 서로 다른 3가지', () {
      for (final day in days) {
        final picks = DailyCandidates.forDate(day);
        expect(picks, hasLength(3));
        expect(picks.toSet(), hasLength(3), reason: day.key);
        expect(EselPaint.values, containsAll(picks));
      }
    });

    test('같은 날은 몇 번 열어도 같은 후보', () {
      for (final day in days.take(10)) {
        expect(DailyCandidates.forDate(day), DailyCandidates.forDate(day));
      }
    });

    test('날짜가 바뀌면 후보도 바뀌고, 12색이 모두 돌아온다', () {
      final sets = days.map((d) => DailyCandidates.forDate(d).toSet()).toList();
      var changed = 0;
      for (var i = 1; i < sets.length; i++) {
        if (sets[i].difference(sets[i - 1]).isNotEmpty) changed++;
      }
      expect(changed, greaterThan(days.length * 0.8));
      expect(sets.expand((s) => s).toSet(), EselPaint.values.toSet());
    });

    test('디자인 시안의 날(2026-09-06)은 카멜·라일락·올리브', () {
      expect(DailyCandidates.forDate(DailyCandidates.demoDate), [
        EselPaint.camel,
        EselPaint.lilac,
        EselPaint.olive,
      ]);
    });
  });
}
