import 'package:flutter/foundation.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_clock.dart';
import '../../../../core/time/service_date.dart';
import '../../../drafts/data/local_library.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../../domain/rules/daily_candidates.dart';

/// 로그인한 사람의 "오늘": 서비스 날짜, 후보 3색, 오늘 발행 여부, 호수.
///
/// 하루 한 호(P04)와 같은 색 잠금(P01)이 모두 여기서 계산한 값을 쓴다. 화면이 따로
/// 날짜나 발행 여부를 들고 있지 않는다.
class TodayController extends ChangeNotifier {
  final ServiceClock clock;
  LocalLibrary? _library;
  String? _ownerId;
  bool _isMinor = false;
  EselPaint? _picked;

  late ServiceDate _today;
  List<CoverDraft> _issues = const [];

  TodayController({required this.clock}) {
    _today = clock.today;
  }

  ServiceDate get today => _today;
  List<EselPaint> get candidates => DailyCandidates.forDate(_today);

  bool get isSignedIn => _ownerId != null;
  String? get ownerId => _ownerId;

  /// 서가 순서(최신 호가 앞).
  List<CoverDraft> get issues => _issues;
  int get issueCount => _issues.length;

  /// 오늘 발행한 호. 없으면 null.
  CoverDraft? get todayIssue {
    for (final issue in _issues) {
      if (issue.publishedOn == _today.key) return issue;
    }
    return null;
  }

  bool get hasPublishedToday => todayIssue != null;

  /// 캡슐·만들기에 보이는 내 오늘의 색. 발행했으면 그 호의 색, 아니면 고른 후보.
  EselPaint get myColor {
    final published = todayIssue;
    if (published != null) return published.color;
    final picked = _picked;
    if (picked != null && candidates.contains(picked)) return picked;
    return candidates.first;
  }

  SameColorViewer get viewer => _ownerId == null
      ? SameColorViewer.reader(_today)
      : SameColorViewer(
          today: _today,
          candidates: candidates,
          hasPublishedToday: hasPublishedToday,
          isMinor: _isMinor,
        );

  /// 기기 보관함을 연결한다. 발행·삭제가 일어나면 다시 계산한다.
  set library(LocalLibrary? library) {
    if (identical(library, _library)) return;
    _library?.removeListener(refresh);
    _library = library;
    _library?.addListener(refresh);
    refresh();
  }

  /// 로그인·로그아웃 때 부른다.
  void bindUser({required String? ownerId, bool isMinor = false}) {
    _ownerId = ownerId;
    _isMinor = isMinor;
    _picked = null;
    refresh();
  }

  /// 오늘 후보 중 하나를 고른다. 고르는 것만으로는 어떤 방도 열리지 않는다(P03).
  void pick(EselPaint color) {
    if (!candidates.contains(color) || _picked == color) return;
    _picked = color;
    notifyListeners();
  }

  /// 날짜와 발행 기록을 다시 읽는다.
  void refresh() {
    _today = clock.today;
    final owner = _ownerId;
    _issues = owner == null || _library == null
        ? const []
        : _library!.issuesFor(owner);
    notifyListeners();
  }

  @override
  void dispose() {
    _library?.removeListener(refresh);
    super.dispose();
  }
}
