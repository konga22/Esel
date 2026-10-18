import '../../../core/time/service_date.dart';
import '../../drafts/domain/cover_draft.dart';

enum CollectionUnit { day, week, month }

class CollectionPeriod {
  final CollectionUnit unit;
  final ServiceDate start;
  const CollectionPeriod._(this.unit, this.start);
  factory CollectionPeriod.at(CollectionUnit unit, ServiceDate day) {
    final start = switch (unit) {
      CollectionUnit.day => day,
      CollectionUnit.week => day.addDays(
        1 - DateTime.utc(day.year, day.month, day.day).weekday,
      ),
      CollectionUnit.month => ServiceDate(day.year, day.month, 1),
    };
    return CollectionPeriod._(unit, start);
  }
  ServiceDate get end => switch (unit) {
    CollectionUnit.day => start.addDays(1),
    CollectionUnit.week => start.addDays(7),
    CollectionUnit.month => _month(1),
  };
  ServiceDate _month(int offset) {
    final date = DateTime.utc(start.year, start.month + offset, 1);
    return ServiceDate(date.year, date.month, 1);
  }

  CollectionPeriod move(int offset) => CollectionPeriod.at(unit, switch (unit) {
    CollectionUnit.day => start.addDays(offset),
    CollectionUnit.week => start.addDays(offset * 7),
    CollectionUnit.month => _month(offset),
  });
  String get key => '${unit.name}:${start.key}';
  String get title =>
      '${switch (unit) {
        CollectionUnit.day => '일간',
        CollectionUnit.week => '주간',
        CollectionUnit.month => '월간',
      }} 표지 전시';
  String get label => '${start.label} ~ ${end.addDays(-1).label}';
  bool contains(CoverDraft issue) {
    final day = ServiceDate.tryParse(issue.publishedOn);
    return day != null && !day.isBefore(start) && day.isBefore(end);
  }
}

class FeaturedCover {
  final CoverDraft issue;
  final String reason;
  const FeaturedCover(this.issue, this.reason);
}

const selectionReasons = ['주제에 맞는 착장', '색 활용', '다양한 스타일'];

String validateSelectionReason(String reason) {
  final text = reason.trim();
  if (text.isEmpty || text.runes.length > 120) {
    throw const FormatException('선정 이유를 1~120자로 적어 주세요.');
  }
  return text;
}
