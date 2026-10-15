import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/today/presentation/controllers/today_controller.dart';

void main() {
  late Directory directory;
  late LocalLibrary library;
  late ManualServiceClock clock;
  late TodayController today;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('esel-today-test-');
    library = LocalLibrary(directory);
    await library.load();
    // 서울 2026-10-15 23:00 (UTC 14:00).
    clock = ManualServiceClock(DateTime.utc(2026, 10, 15, 14));
    today = TodayController(clock: clock)..library = library;
    today.bindUser(ownerId: 'owner-a');
  });
  tearDown(() async {
    today.dispose();
    library.dispose();
    await directory.delete(recursive: true);
  });

  CoverDraft draft() => CoverDraft(
    id: library.newId(),
    photoPath: 'photo.png',
    masthead: 'owner',
    color: today.candidates.first,
    faceConfirmed: true,
    updatedAt: clock.now(),
  );

  group('DEV-09 P04 서비스 날짜(Asia/Seoul)와 하루 한 호', () {
    test('서비스 날짜는 기기 시간대가 아니라 서울 기준이다', () {
      expect(today.today, const ServiceDate(2026, 10, 15));
      clock.set(DateTime.utc(2026, 10, 15, 15, 30)); // 서울 10-16 00:30
      today.refresh();
      expect(today.today, const ServiceDate(2026, 10, 16));
    });

    test('하루 두 번째 발행은 거절되고, 자정이 지나면 다음 호를 낼 수 있다', () async {
      final first = await today.publish(draft());
      expect(first.issueNumber, 1);
      expect(first.publishedOn, '2026-10-15');
      expect(today.hasPublishedToday, isTrue);
      await expectLater(today.publish(draft()), throwsFormatException);
      expect(today.issueCount, 1);

      clock.set(DateTime.utc(2026, 10, 15, 15, 0, 5)); // 서울 10-16 00:00:05
      today.refresh();
      expect(today.hasPublishedToday, isFalse);
      final second = await today.publish(draft());
      expect(second.issueNumber, 2);
      expect(second.publishedOn, '2026-10-16');
      expect(library.issuesFor('owner-a').map((d) => d.issueNumber), [2, 1]);
    });

    test('편집하는 사이 자정이 지나면 발행 직전에 새 날짜로 계산한다', () async {
      await today.publish(draft());
      clock.advance(const Duration(hours: 2)); // 서울 10-16 01:00, refresh 없이
      final next = await today.publish(draft());
      expect(next.publishedOn, '2026-10-16');
      expect(next.issueNumber, 2);
    });

    test('오늘 후보가 아닌 색으로는 발행하지 않는다(P17)', () async {
      final outside = EselPaint.values.firstWhere(
        (c) => !today.candidates.contains(c),
      );
      await expectLater(
        today.publish(draft().copyWith(color: outside)),
        throwsFormatException,
      );
      expect(today.hasPublishedToday, isFalse);
    });

    testWidgets('자정 타이머가 날짜를 넘기면 다시 계산한다', (tester) async {
      await tester.runAsync(() => today.publish(draft()));
      expect(today.hasPublishedToday, isTrue);
      today.watchMidnight(); // 서울 자정까지 1시간 + 1초
      clock.set(DateTime.utc(2026, 10, 15, 15, 0, 1));
      await tester.pump(const Duration(hours: 1, seconds: 2));
      expect(today.today, const ServiceDate(2026, 10, 16));
      expect(today.hasPublishedToday, isFalse);
      today.stopWatchingMidnight();
    });
  });
}
