import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../../data/sources/magazine_source.dart';
import '../../domain/models/magazine_models.dart';

export '../../domain/models/magazine_models.dart';

/// 서가 상태. 데이터는 [MagazineSource](mock 또는 서버)에서만 받는다.
class MagazineController extends ChangeNotifier {
  final MagazineSource source;

  MagazineController(this.source);

  ShelfViewMode _viewMode = ShelfViewMode.covers;
  MagazineProfile? _profile;
  bool _loading = false;
  String? _error;
  String? _ownerId;
  SameColorViewer? _viewer;
  String? _viewerId;
  String? _masthead;
  int _request = 0;

  ShelfViewMode get viewMode => _viewMode;
  bool get isLoading => _loading;
  String? get errorMessage => _error;

  /// 지금 보고 있는 잡지. 다른 사람의 서가로 바뀌는 중이면 null.
  MagazineProfile? get profile =>
      _profile?.ownerId == _ownerId ? _profile : null;

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
    if (changed || _profile == null) load();
  }

  Future<void> load() async {
    final ownerId = _ownerId;
    final viewer = _viewer;
    if (ownerId == null || viewer == null) return;
    final request = ++_request;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final profile = await source.magazine(
        ownerId,
        viewer: viewer,
        viewerId: _viewerId,
        masthead: _masthead,
      );
      if (request != _request) return;
      _profile = profile;
      if (profile == null) _error = '이 잡지를 찾지 못했어요.';
    } on Failure catch (failure) {
      if (request != _request) return;
      _error = failure.message;
    } catch (_) {
      if (request != _request) return;
      _error = '서가를 불러오지 못했어요. 다시 시도해 주세요.';
    }
    _loading = false;
    notifyListeners();
  }
}
