import '../../../core/time/service_date.dart';
import '../../drafts/domain/cover_draft.dart';

/// Local programme: two participation types per Seoul calendar week.
/// IDs are stable; no remote endpoint is assumed by this model.
class StyleChallenge {
  final ServiceDate start;
  final bool restyle;
  const StyleChallenge(this.start, {this.restyle = false});
  ServiceDate get end => start.addDays(7);
  String get id => '${start.key}:${restyle ? 'restyle' : 'weekly'}';
  String get title => restyle ? '같은 옷, 다른 코디' : '주간 드레스코드';
  String get topic => restyle
      ? '지난 표지 속 옷을 다르게 입어 봐요'
      : ['가방으로 포인트', '겹쳐 입기', '데님', '비 오는 날'][(start.startsAt
                    .difference(DateTime.utc(2026, 1, 4, 15))
                    .inDays ~/
                7) %
            4];
  String get instruction => restyle
      ? '내 지난 날짜 표지를 골라 오늘 착장과 연결해요. 같은 옷인지는 직접 확인해 주세요.'
      : '오늘 후보 색 중 하나와 이번 주 주제를 함께 표현해요. 새 옷을 살 필요는 없어요.';
  String get period =>
      '${start.shortLabel} ~ ${end.addDays(-1).shortLabel} · 서울 시간';
  bool isOpen(ServiceDate today) =>
      !today.isBefore(start) && today.isBefore(end);
  static List<StyleChallenge> forWeek(ServiceDate date) {
    final start = date.addDays(
      1 - DateTime.utc(date.year, date.month, date.day).weekday,
    );
    return [StyleChallenge(start), StyleChallenge(start, restyle: true)];
  }

  static StyleChallenge? resolve(String? id) {
    if (id == null) return null;
    final parts = id.split(':');
    if (parts.length != 2 || !['weekly', 'restyle'].contains(parts[1])) {
      return null;
    }
    final start = ServiceDate.tryParse(parts[0]);
    if (start == null ||
        DateTime.utc(start.year, start.month, start.day).weekday != 1) {
      return null;
    }
    return StyleChallenge(start, restyle: parts[1] == 'restyle');
  }

  void validate({
    required ServiceDate today,
    required String ownerId,
    required CoverDraft issue,
    required List<CoverDraft> publications,
    String? previousId,
  }) {
    if (!isOpen(today)) {
      throw const FormatException('참여 기간이 끝났어요. 이번 주 주제를 확인해 주세요.');
    }
    if (ownerId.isEmpty || issue.ownerId != ownerId) {
      throw const FormatException('내 표지만 연결할 수 있어요.');
    }
    final published = ServiceDate.tryParse(issue.publishedOn);
    if (published != null && published != today) {
      throw const FormatException('오늘 발행한 표지로 참여해 주세요.');
    }
    if (!restyle && previousId != null) {
      throw const FormatException('이 주제에는 비교 표지가 필요하지 않아요.');
    }
    if (restyle) {
      final previous = publications
          .where(
            (p) =>
                p.id == previousId &&
                p.ownerId == ownerId &&
                p.issueNumber > 0 &&
                p.id != issue.id,
          )
          .firstOrNull;
      final date = ServiceDate.tryParse(previous?.publishedOn);
      if (date == null || !date.isBefore(today)) {
        throw const FormatException('내 지난 날짜의 발행 표지를 골라 주세요.');
      }
    }
  }
}
