import '../../../../core/design/tokens.g.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../../../issue/domain/models/public_issue.dart';

enum ShelfViewMode { covers, spines }

/// 한 사람의 잡지(스케치북). 구독자 수 같은 반응 숫자는 두지 않는다(P18).
class MagazineProfile {
  final String ownerId;
  final String masthead;
  final String? nextCursor;
  final bool? subscribed;
  final String bio;

  /// 올린 호 수. 호수는 올리기로만 오르므로 최신 호수와 같다(P04).
  final int totalIssues;

  /// 오늘 올린 호의 색(보는 사람에게 열린 경우만).
  final EselPaint? todayColor;

  /// 지난 호(최신이 앞). 보는 사람에게 잠긴 오늘의 캔버스는 빠져 있다(P01).
  final List<PublicIssue> issues;

  /// 내 호의 편집 원본. 내 스케치북에서 표지를 그대로 다시 그린다.
  final Map<String, CoverDraft> localCovers;
  final bool isMine;

  const MagazineProfile({
    this.nextCursor,
    this.subscribed,
    this.bio = '',
    required this.ownerId,
    required this.masthead,
    required this.totalIssues,
    required this.issues,
    this.todayColor,
    this.localCovers = const {},
    this.isMine = false,
  });
}
