import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';

void main() {
  const today = ServiceDate(2026, 10, 15);
  const candidates = [EselPaint.camel, EselPaint.lilac, EselPaint.olive];
  const before = SameColorViewer(
    today: today,
    candidates: candidates,
    hasPublishedToday: false,
    isMinor: false,
  );

  // 같은 시각이 둘(c3, c4)이면 id 순서로 정한다.
  final covers = [
    for (final (id, minute) in [
      ('c1', 9 * 60),
      ('c2', 13 * 60),
      ('c3', 8 * 60),
      ('c4', 8 * 60),
      ('c5', 11 * 60),
    ])
      RoomCover(
        id: id,
        publishedAt: today.startsAt.add(Duration(minutes: minute)),
      ),
  ];

  SameColorRoom room(
    EselPaint color, {
    SameColorViewer viewer = before,
    ServiceDate date = today,
  }) => SameColorRule.evaluateRoom(
    color: color,
    date: date,
    viewer: viewer,
    covers: covers,
  );

  group('DEV-02 P01 같은 색 방(2026-10-15 규칙)', () {
    test('발행 전에는 후보 3색 방이 모두 최신 3장 + 개수만', () {
      for (final color in candidates) {
        final res = room(color);
        expect(res.access, SameColorRoomAccess.preview, reason: '$color');
        expect(res.visibleCoverIds, ['c2', 'c5', 'c1']);
        expect(res.hiddenCount, 2);
        expect(res.total, 5);
        expect(res.visibleCoverIds, isNot(contains('c3')));
        expect(SameColorRule.isLockedToday(color, before), isTrue);
      }
      expect(SameColorRule.bannerMessage, '발행하면 함께 펼쳐집니다');
    });

    test('후보가 아닌 9색 방은 발행 전에도 열려 있다', () {
      for (final color in EselPaint.values.where(
        (c) => !candidates.contains(c),
      )) {
        final res = room(color);
        expect(res.access, SameColorRoomAccess.open, reason: '$color');
        expect(res.visibleCoverIds, hasLength(5));
        expect(res.hiddenCount, 0);
        expect(SameColorRule.isLockedToday(color, before), isFalse);
      }
    });

    test('오늘 발행하면 모든 방이 열린다', () {
      const published = SameColorViewer(
        today: today,
        candidates: candidates,
        hasPublishedToday: true,
        isMinor: false,
      );
      for (final color in EselPaint.values) {
        final res = room(color, viewer: published);
        expect(res.access, SameColorRoomAccess.open);
        expect(res.visibleCoverIds, ['c2', 'c5', 'c1', 'c3', 'c4']);
        expect(res.hiddenCount, 0);
      }
    });

    test('자정이 지나면 어제 방은 지난 날짜라 열리고, 새 날짜 후보 방은 다시 미리보기', () {
      const tomorrow = SameColorViewer(
        today: ServiceDate(2026, 10, 16),
        candidates: [EselPaint.sage, EselPaint.camel, EselPaint.cobalt],
        hasPublishedToday: false,
        isMinor: false,
      );
      expect(
        room(EselPaint.camel, viewer: tomorrow, date: today).access,
        SameColorRoomAccess.open,
      );
      expect(
        room(EselPaint.lilac, viewer: tomorrow, date: today).hiddenCount,
        0,
      );
      expect(
        room(
          EselPaint.camel,
          viewer: tomorrow,
          date: const ServiceDate(2026, 10, 16),
        ).access,
        SameColorRoomAccess.preview,
      );
      expect(SameColorRule.isLockedToday(EselPaint.sage, tomorrow), isTrue);
      expect(SameColorRule.isLockedToday(EselPaint.lilac, tomorrow), isFalse);
    });

    test('미성년자는 잠금이 없다', () {
      const minor = SameColorViewer(
        today: today,
        candidates: candidates,
        hasPublishedToday: false,
        isMinor: true,
      );
      for (final color in candidates) {
        expect(room(color, viewer: minor).access, SameColorRoomAccess.open);
        expect(SameColorRule.isLockedToday(color, minor), isFalse);
      }
    });

    test('미래 날짜 방은 닫혀 있고 표지를 주지 않는다(P02)', () {
      final res = room(EselPaint.sage, date: const ServiceDate(2026, 10, 16));
      expect(res.access, SameColorRoomAccess.closed);
      expect(res.visibleCoverIds, isEmpty);
    });

    test('비로그인 독자에게는 후보가 없어 잠긴 방이 없다', () {
      const reader = SameColorViewer.reader(today);
      for (final color in EselPaint.values) {
        expect(SameColorRule.isLockedToday(color, reader), isFalse);
      }
    });
  });

  group('ServiceDate는 Asia/Seoul 기준', () {
    test('UTC 15시가 서울 자정이다', () {
      expect(
        ServiceDate.of(DateTime.utc(2026, 10, 15, 14, 59)),
        const ServiceDate(2026, 10, 15),
      );
      expect(
        ServiceDate.of(DateTime.utc(2026, 10, 15, 15)),
        const ServiceDate(2026, 10, 16),
      );
      expect(
        const ServiceDate(2026, 10, 16).startsAt,
        DateTime.utc(2026, 10, 15, 15),
      );
    });

    test('키와 표기', () {
      const date = ServiceDate(2026, 9, 6);
      expect(date.key, '2026-09-06');
      expect(date.label, '2026. 9. 6.');
      expect(date.weekdayLabel, '일요일');
      expect(date.dayOfYear, 249);
      expect(ServiceDate.tryParse('2026-02-30'), isNull);
      expect(ServiceDate.tryParse('2026-09-06'), date);
    });
  });
}
