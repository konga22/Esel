import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../../data/sources/magazine_source.dart';
import '../../domain/models/magazine_models.dart';

export '../../domain/models/magazine_models.dart';

/// 스케치북 상태. 데이터는 [MagazineSource](mock 또는 서버)에서만 받는다.
class MagazineController extends ChangeNotifier {
  final MagazineSource source;

  MagazineController(this.source);

  ShelfViewMode _viewMode = ShelfViewMode.covers;
  MagazineProfile? _profile;
  bool _loading = false;
  String? _error, _moreError;
  bool _loadingMore = false;
  String? get moreError => _moreError;
  bool get isLoadingMore => _loadingMore;
  String? _ownerId;
  SameColorViewer? _viewer;
  String? _viewerId;
  String? _masthead;
  int _request = 0;

  ShelfViewMode get viewMode => _viewMode;
  bool get isLoading => _loading;
  String? get errorMessage => _error;

  /// 지금 보고 있는 잡지. 다른 사람의 스케치북으로 바뀌는 중이면 null.
  MagazineProfile? get profile =>
      _profile?.ownerId == _ownerId ? _profile : null;

  void clear() {
    _request++;
    _profile = null;
    _ownerId = null;
    _error = null;
    _moreError = null;
    _loadingMore = false;
    _loading = false;
  }

  void toggleViewMode() {
    _viewMode = _viewMode == ShelfViewMode.covers
        ? ShelfViewMode.spines
        : ShelfViewMode.covers;
    notifyListeners();
  }

  void configure({
    required String ownerId,
    required SameColorViewer viewer,
    String? viewerId,
    String? masthead,
  }) {
    final changed =
        ownerId != _ownerId ||
        viewer != _viewer ||
        viewerId != _viewerId ||
        masthead != _masthead;
    _ownerId = ownerId;
    _viewer = viewer;
    _viewerId = viewerId;
    _masthead = masthead;
    if (changed || (_profile == null && !_loading && _error == null)) load();
  }

  Future<void> load({bool more = false}) async {
    final ownerId = _ownerId;
    final viewer = _viewer;
    if (ownerId == null || viewer == null) return;
    if (more && (_loading || _loadingMore || _profile?.nextCursor == null)) {
      return;
    }
    final request = ++_request;
    final previous = _profile;
    _loading = !more;
    _loadingMore = more;
    _moreError = null;
    if (!more) _profile = null;
    _error = null;
    notifyListeners();
    try {
      final profile = await source.magazine(
        ownerId,
        viewer: viewer,
        viewerId: _viewerId,
        masthead: _masthead,
        cursor: more ? previous?.nextCursor : null,
      );
      if (request != _request) return;
      _profile = !more || profile == null || previous == null
          ? profile
          : MagazineProfile(
              ownerId: profile.ownerId,
              masthead: profile.masthead,
              totalIssues: profile.totalIssues,
              isMine: profile.isMine,
              todayColor: profile.todayColor,
              nextCursor: profile.nextCursor,
              subscribed: profile.subscribed,
              bio: profile.bio,
              issues: {
                for (final v in [...previous.issues, ...profile.issues])
                  v.id: v,
              }.values.toList(),
              localCovers: {...previous.localCovers, ...profile.localCovers},
            );
      if (profile == null) {
        if (more) {
          _profile = previous;
          _moreError = '다음 캔버스를 불러오지 못했어요.';
        } else {
          _error = '이 스케치북을 찾지 못했어요.';
        }
      }
    } catch (failure) {
      if (request != _request) return;
      final message = failure is Failure
          ? failure.message
          : '스케치북을 불러오지 못했어요. 다시 시도해 주세요.';
      if (more) {
        _profile = previous;
        _moreError = message;
      } else {
        _profile = null;
        _error = message;
      }
    }
    _loading = false;
    _loadingMore = false;
    notifyListeners();
  }
}
