import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_date.dart';
import '../../../issue/domain/models/public_issue.dart';

enum FeedTab { all, subscribed }

/// 오늘의 표지 피드 한 번 받은 것. 첫 호가 표지(사인 Esel), 나머지는 안쪽 지면이다(P16).
class FeedPage {
  final ServiceDate date;

  /// 앱의 오늘의 표지 호수. 사람마다의 개인 호수와 다르다.
  final int appIssueNumber;
  final List<PublicIssue> issues;

  /// 오늘 올리기 전이라 잠긴 같은 색(후보 3색) 표지를 뺐는지(P01). 안내를 한 번 넣는다.
  final bool heldBack;

  /// 비로그인이라 받지 않은 안쪽 지면 수(P12, 2쪽까지만 받음).
  final int pagesForMembers;

  /// 오늘 색별 올리기 인원(같은 색 인원, 공개 숫자 P18).
  final Map<EselPaint, int> sameColorCounts;

  const FeedPage({
    required this.date,
    required this.appIssueNumber,
    required this.issues,
    this.heldBack = false,
    this.pagesForMembers = 0,
    this.sameColorCounts = const {},
  });

  int sameColorCount(EselPaint color) => sameColorCounts[color] ?? 0;

  PublicIssue? get cover => issues.isEmpty ? null : issues.first;
  List<PublicIssue> get innerPages =>
      issues.length < 2 ? const [] : issues.sublist(1);
}
