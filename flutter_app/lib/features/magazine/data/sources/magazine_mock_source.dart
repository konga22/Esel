import '../../../drafts/data/local_library.dart';
import '../../../issue/data/demo_issue_catalog.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../../domain/models/magazine_models.dart';
import 'magazine_source.dart';

/// 시연 스케치북: 스케치북은 이 기기 보관함, 다른 사람은 예시 인물의 지난 호.
class MagazineMockSource implements MagazineSource {
  static const int shelfSize = 24;
  final LocalLibrary? Function() _library;

  MagazineMockSource({LocalLibrary? Function()? library})
    : _library = library ?? (() => null);

  @override
  Future<MagazineProfile?> magazine(
    String ownerId, {
    required SameColorViewer viewer,
    String? viewerId,
    String? masthead,
    String? cursor,
  }) async {
    if (ownerId == viewerId) {
      final drafts = _library()?.issuesFor(ownerId) ?? const [];
      final issues = drafts.map(DemoIssueCatalog.fromLocal).toList();
      return MagazineProfile(
        ownerId: ownerId,
        masthead: masthead ?? (drafts.isEmpty ? '' : drafts.first.masthead),
        totalIssues: _library()?.publicationCount(ownerId)??issues.length,
        todayColor: issues.isNotEmpty && issues.first.date == viewer.today
            ? issues.first.color
            : null,
        issues: issues,
        localCovers: {for (final d in drafts) d.id: d},
        isMine: true,
      );
    }
    final person = DemoIssueCatalog.personOf(ownerId);
    if (person == null) return null;
    final issues = <PublicIssue>[];
    for (var i = 0; i < shelfSize; i++) {
      final issue = DemoIssueCatalog.issueOf(
        person,
        viewer.today.addDays(-i),
        today: viewer.today,
      );
      if (issue == null) break;
      // 보는 사람에게 잠긴 오늘의 캔버스(후보 색, 올리기 전)는 스케치북에서도 보이지 않는다(P01).
      final access = SameColorRule.accessFor(
        color: issue.color,
        date: issue.date,
        viewer: viewer,
      );
      if (access != SameColorRoomAccess.open) continue;
      issues.add(issue);
    }
    final today = issues.isNotEmpty && issues.first.date == viewer.today
        ? issues.first
        : null;
    return MagazineProfile(
      ownerId: ownerId,
      masthead: person.name,
      totalIssues: DemoIssueCatalog.issueNumberOn(person, viewer.today),
      todayColor: today?.color,
      issues: issues,
    );
  }
}
