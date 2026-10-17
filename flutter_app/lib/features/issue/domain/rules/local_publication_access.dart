import '../../../drafts/domain/cover_draft.dart';
import '../../../../core/time/service_date.dart';
import '../../../stand/domain/rules/same_color_rule.dart';

/// 콘텐츠를 묶기 전에 공개 여부를 먼저 적용한다. 잠긴 색의 추가 미리보기는 만들지 않는다.
List<CoverDraft> visibleLocalPublications(
  Iterable<CoverDraft> all,
  SameColorViewer viewer,
  String viewerId,
) {
  return all.where((issue) {
    final date = ServiceDate.tryParse(issue.publishedOn);
    if (issue.issueNumber <= 0 ||
        issue.ownerId.isEmpty ||
        date == null ||
        date.isAfter(viewer.today)) {
      return false;
    }
    return issue.ownerId == viewerId ||
        SameColorRule.accessFor(
              color: issue.color,
              date: date,
              viewer: viewer,
            ) ==
            SameColorRoomAccess.open;
  }).toList()..sort((a, b) {
    final date = b.publishedOn!.compareTo(a.publishedOn!);
    return date != 0 ? date : a.id.compareTo(b.id);
  });
}
