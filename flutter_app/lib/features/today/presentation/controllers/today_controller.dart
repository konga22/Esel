import 'dart:async';
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
/// 날짜나 발행 여부를 들고 있지 않는다. 날짜는 [clock] 하나에서만 읽고, 로그인·앱 재개·
/// 서울 자정·발행 때 다시 계산한다.
class TodayController extends ChangeNotifier {
  final ServiceClock clock;
  LocalLibrary? _library;
  String? _ownerId;
  bool _isMinor = false;
  EselPaint? _picked;
  Timer? _midnight;

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

  /// 날짜와 발행 기록을 다시 읽는다. 앱 재개·자정·발행 직후에 부른다.
  void refresh() {
    final previous = _today;
    _today = clock.today;
    if (_today != previous) _picked = null;
    final owner = _ownerId;
    _issues = owner == null || _library == null
        ? const []
        : _library!.issuesFor(owner);
    notifyListeners();
  }

  /// 서울 자정에 다시 계산하도록 타이머를 건다. 앱이 켜져 있는 동안만(화면이 멈추면
  /// 타이머가 늦을 수 있어서 앱 재개 때도 [refresh]한다).
  void watchMidnight() {
    _midnight?.cancel();
    final wait = _today.endsAt.difference(clock.now());
    _midnight = Timer(
      (wait.isNegative ? Duration.zero : wait) + const Duration(seconds: 1),
      () {
        refresh();
        watchMidnight();
      },
    );
  }

  void stopWatchingMidnight() {
    _midnight?.cancel();
    _midnight = null;
  }

  /// 오늘 호를 발행한다(P04). 발행 직전에 날짜를 다시 읽어, 자정을 넘긴 편집은 새 날짜의
  /// 호가 된다. 하루 두 번째 발행과 후보 밖의 색(P17)은 거절한다.
  Future<CoverDraft> publish(CoverDraft draft) async {
    refresh();
    final owner = _ownerId;
    final library = _library;
    if (owner == null || library == null) {
      throw const FormatException('로그인이 필요해요.');
    }
    if (!candidates.contains(draft.color)) {
      throw const FormatException('오늘의 후보 색 중 하나로 발행해 주세요.');
    }
    return library.publish(draft, owner, on: _today, at: clock.now());
  }

  @override
  void dispose() {
    stopWatchingMidnight();
    _library?.removeListener(refresh);
    super.dispose();
  }
}
