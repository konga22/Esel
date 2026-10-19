import '../../../media/domain/rules/media_upload_policy.dart';
import '../../../../core/errors/failures.dart';
import '../../data/sources/today_remote_source.dart';
import '../../../magazine/data/sources/magazine_remote_source.dart';
import '../../../media/domain/models/face_layout_mode.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_clock.dart';
import '../../../../core/time/service_date.dart';
import '../../../drafts/data/local_library.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../../domain/rules/daily_candidates.dart';

/// 로그인한 사람의 "오늘": 서비스 날짜, 후보 3색, 오늘 올리기 여부, 호수.
///
/// 하루 한 호(P04)와 같은 색 잠금(P01)이 모두 여기서 계산한 값을 쓴다. 화면이 따로
/// 날짜나 올리기 여부를 들고 있지 않는다. 날짜는 [clock] 하나에서만 읽고, 로그인·앱 재개·
/// 서울 자정·올리기 때 다시 계산한다.
class TodayController extends ChangeNotifier {
  final ServiceClock clock;
  final Future<CoverDraft> Function(CoverDraft)? publishRemote;
  bool _publishing = false;
  int _publishRequest = 0;
  final TodayRemoteSource? remote;
  final MagazineRemoteSource? remoteMagazine;
  bool loading = false;
  String? error;
  bool get isRemote => remote != null;
  List<EselPaint> _remoteCandidates = const [];
  int _remoteCount = 0, _request = 0;
  bool _remotePublished = false;
  Future<void>? _inFlight;
  Future<void> _choices = Future.value();
  int _accountVersion = 0;
  bool get hasTodayData => !isRemote || _remoteCandidates.isNotEmpty;

  LocalLibrary? _library;
  String? _ownerId;
  bool _isMinor = false, _hasProfile = true;
  EselPaint? _picked;
  Timer? _midnight;

  late ServiceDate _today;
  List<CoverDraft> _issues = const [];

  TodayController({
    required this.clock,
    this.remote,
    this.remoteMagazine,
    this.publishRemote,
  }) {
    _today = clock.today;
  }

  ServiceDate get today => _today;
  List<EselPaint> get candidates =>
      isRemote ? _remoteCandidates : DailyCandidates.forDate(_today);

  bool get isSignedIn => _ownerId != null;
  String? get ownerId => _ownerId;

  /// 스케치북 순서(최신 호가 앞).
  List<CoverDraft> get issues => _issues;
  int get issueCount => isRemote
      ? _remoteCount
      : _ownerId == null
      ? 0
      : _library?.publicationCount(_ownerId!) ?? _issues.length;

  /// 오늘 올린 호. 없으면 null.
  CoverDraft? get todayIssue {
    for (final issue in _issues) {
      if (issue.publishedOn == _today.key) return issue;
    }
    return null;
  }

  bool get hasPublishedToday =>
      (isRemote
          ? (_today == clock.today && _remotePublished)
          : todayIssue != null) ||
      (!isRemote &&
          _ownerId != null &&
          _library?.hasPublishedOn(_ownerId!, _today) == true);

  /// 캡슐·만들기에 보이는 내 오늘의 색. 올렸으면 그 호의 색, 아니면 고른 후보,
  /// 그것도 없으면 저장해 둔 초안의 색(오늘 후보일 때), 마지막으로 첫 후보.
  EselPaint get myColor {
    final published = todayIssue;
    if (published != null) return published.color;
    for (final color in [_picked, _draftColor]) {
      if (color != null && candidates.contains(color)) return color;
    }
    return candidates.firstOrNull ?? EselPaint.powder;
  }

  EselPaint? get _draftColor {
    final owner = _ownerId;
    final library = _library;
    if (owner == null || library == null) return null;
    CoverDraft? latest;
    for (final draft in library.drafts) {
      if (draft.ownerId != owner || draft.issueNumber != 0) continue;
      if (latest == null || draft.updatedAt.isAfter(latest.updatedAt)) {
        latest = draft;
      }
    }
    return latest?.color;
  }

  SameColorViewer get viewer => _ownerId == null
      ? SameColorViewer.reader(_today)
      : SameColorViewer(
          today: _today,
          candidates: candidates,
          hasPublishedToday: hasPublishedToday,
          isMinor: _isMinor,
        );

  /// 기기 보관함을 연결한다. 올리기·삭제가 일어나면 다시 계산한다.
  set library(LocalLibrary? library) {
    if (identical(library, _library)) return;
    _library?.removeListener(refresh);
    _library = library;
    if (!isRemote) _library?.addListener(refresh);
    refresh();
  }

  /// 로그인·로그아웃 때 부른다.
  void bindUser({
    required String? ownerId,
    bool isMinor = false,
    bool hasProfile = true,
  }) {
    // 같은 사람이면 고른 색을 그대로 둔다(로그인 중 상태 알림마다 불릴 수 있다).
    final changed = ownerId != _ownerId;
    final profileChanged = hasProfile != _hasProfile;
    _hasProfile = hasProfile;
    if (changed) {
      _publishRequest++;
      _publishing = false;
      _request++;
      _accountVersion++;
      _choices = Future.value();
      _inFlight = null;
      _remoteCandidates = const [];
      _remoteCount = 0;
      _remotePublished = false;
      _issues = const [];
      _picked = null;
    }

    _ownerId = ownerId;
    _isMinor = isMinor;
    if (isRemote) {
      if ((changed || profileChanged) && ownerId != null) {
        if (profileChanged && !changed) {
          _request++;
          _inFlight = null;
        }
        reload();
      } else if (ownerId == null) {
        loading = false;
        error = null;
        notifyListeners();
      }
      return;
    }
    refresh();
  }

  /// 오늘 후보 중 하나를 고른다. 고르는 것만으로는 어떤 방도 열리지 않는다(P03).
  void pick(EselPaint color) {
    if (!candidates.contains(color) || _picked == color) return;
    if (isRemote) {
      choose(color);
      return;
    }
    _picked = color;
    notifyListeners();
  }

  /// 날짜와 올리기 기록을 다시 읽는다. 앱 재개·자정·올리기 직후에 부른다.
  void refresh() {
    if (isRemote) {
      if (_ownerId != null) reload();
      return;
    }
    final previous = _today;
    _today = clock.today;
    if (_today != previous) _picked = null;
    final owner = _ownerId;
    _issues = owner == null || _library == null
        ? const []
        : _library!.issuesFor(owner);
    notifyListeners();
  }

  Future<void> reload([EselPaint? choice]) {
    if (!isRemote || _ownerId == null) return Future.value();
    if (_inFlight != null) return _inFlight!;
    final owner = _ownerId, request = ++_request;
    loading = true;
    error = null;
    _inFlight = () async {
      try {
        final value = choice == null
            ? await remote!.today()
            : await remote!.choose(choice);
        final profile = _hasProfile
            ? await remoteMagazine!.page(mine: true)
            : null;
        if (request != _request || owner != _ownerId) return;
        _today = value.date;
        _remoteCandidates = value.candidates;
        _picked = value.selected;
        _remotePublished = value.published;
        _remoteCount = profile?.issueCount ?? 0;
        _issues = [
          for (final issue in [
            if (profile?.today != null) profile!.today!,
            ...?profile?.page.items,
          ])
            CoverDraft(
              id: issue.id,
              photoPath: '',
              masthead: issue.masthead,
              ownerId: owner!,
              color: issue.color,
              caption: issue.caption,
              publishedOn: issue.date.key,
              issueNumber: issue.number,
              faceMode: FaceLayoutMode.original,
              faceConfirmed: true,
              updatedAt: issue.publishedAt,
            ),
        ];
      } catch (e) {
        if (request == _request) {
          // Keep the last server snapshot during a refresh failure.
          error = e is Failure ? e.message : '오늘 상태를 불러오지 못했어요.';
        }
      } finally {
        if (request == _request) {
          loading = false;
          _inFlight = null;
          notifyListeners();
        }
      }
    }();
    notifyListeners();
    return _inFlight!;
  }

  Future<void> choose(EselPaint color) {
    if (!isRemote) {
      pick(color);
      return Future.value();
    }
    final version = _accountVersion;
    final queued = _choices.then((_) async {
      // A color change must wait for the active refresh and earlier choices.
      await _inFlight;
      if (version != _accountVersion || _ownerId == null) return;
      if (hasPublishedToday || !candidates.contains(color)) {
        error = '현재 선택할 수 없는 색이에요. 오늘의 색을 다시 확인해 주세요.';
        notifyListeners();
        return;
      }
      await reload(color);
    });
    _choices = queued;
    return queued;
  }

  /// 서울 자정에 다시 계산하도록 타이머를 건다. 앱이 켜져 있는 동안만(화면이 멈추면
  /// 타이머가 늦을 수 있어서 앱 재개 때도 [refresh]한다).
  void watchMidnight() {
    _midnight?.cancel();
    // Schedule from the clock, never from an old server snapshot.
    final wait = clock.today.endsAt.difference(clock.now());
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

  /// 오늘의 캔버스를 올린다(P04). 올리기 직전에 날짜를 다시 읽어, 자정을 넘긴 편집은 새 날짜의
  /// 호가 된다. 하루 두 번째 올리기과 후보 밖의 색(P17)은 거절한다.
  Future<CoverDraft> publish(CoverDraft draft) async {
    if (isRemote) {
      validateMediaUpload(draft);
      final owner = _ownerId, version = _accountVersion;
      if (owner == null || draft.ownerId != owner) {
        throw const AuthFailure('내 계정의 초안만 올릴 수 있어요.');
      }
      if (_publishing) {
        throw const RuleFailure('사진을 올리는 중이에요. 잠시 기다려 주세요.');
      }
      if (publishRemote == null) {
        throw const NotImplementedFailure('올리기 연결을 확인해 주세요.');
      }
      _publishing = true;
      final operation = ++_publishRequest;
      try {
        await _choices;
        await _inFlight;
        await reload();
        void checkOwner() {
          if (version != _accountVersion || owner != _ownerId) {
            throw const AuthFailure('계정이 변경됐어요.');
          }
        }

        checkOwner();
        if (error != null) {
          throw NetworkFailure(error!);
        }
        if (hasPublishedToday) {
          throw const RuleFailure(
            '오늘은 이미 한 호를 올렸어요.',
            code: 'ISSUE_ALREADY_PUBLISHED',
          );
        }
        if (!candidates.contains(draft.color)) {
          throw const RuleFailure('오늘의 후보 색 중 하나로 올려 주세요.');
        }
        await choose(draft.color);
        checkOwner();
        if (error != null || _picked != draft.color) {
          throw RuleFailure(error ?? '오늘의 색을 저장하지 못했어요.');
        }
        final issue = await publishRemote!(draft);
        checkOwner();
        // 이미 시작된 새로고침이 발행 전 응답으로 성공 상태를 덮지 않게 한다.
        _request++;
        _inFlight = null;
        _today = ServiceDate.tryParse(issue.publishedOn)!;
        _remotePublished = true;
        _remoteCount = issue.issueNumber;
        _issues = [issue, ..._issues.where((v) => v.id != issue.id)];
        error = null;
        loading = false;
        notifyListeners();
        await reload();
        return issue;
      } on RuleFailure catch (failure) {
        if (failure.code == 'ISSUE_ALREADY_PUBLISHED' &&
            version == _accountVersion) {
          await reload();
        }
        rethrow;
      } finally {
        if (operation == _publishRequest) _publishing = false;
      }
    }
    refresh();
    final owner = _ownerId;
    final library = _library;
    if (owner == null || library == null) {
      throw const FormatException('로그인이 필요해요.');
    }
    if (!candidates.contains(draft.color)) {
      throw const FormatException('오늘의 후보 색 중 하나로 올려 주세요.');
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
