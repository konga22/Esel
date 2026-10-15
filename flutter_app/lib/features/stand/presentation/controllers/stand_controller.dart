import 'package:flutter/foundation.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/time/service_date.dart';
import '../../data/sources/stand_source.dart';
import '../../domain/models/stand_shelf.dart';
import '../../domain/rules/same_color_rule.dart';

export '../../domain/models/stand_shelf.dart';

/// 가판대 상태. 데이터는 [StandSource](mock 또는 서버)에서만 받는다.
class StandController extends ChangeNotifier {
  final StandSource source;

  StandController(this.source);

  EselPaint? _selected;
  StandShelf? _shelf;
  bool _loading = false;
  String? _error;
  SameColorViewer? _viewer;
  String? _viewerId;
  int _request = 0;

  /// null이면 전체.
  EselPaint? get selected => _selected;
  StandShelf? get shelf => _shelf;
  bool get isLoading => _loading;
  String? get errorMessage => _error;

  /// 보는 사람이 바뀌면(로그인·발행·자정) 다시 받는다.
  void configure({required SameColorViewer viewer, String? viewerId}) {
    final changed = _viewer != viewer || _viewerId != viewerId;
    _viewer = viewer;
    _viewerId = viewerId;
    if (changed || _shelf == null) load();
  }

  void select(EselPaint? color) {
    if (_selected == color && _shelf != null) return;
    _selected = color;
    load();
  }

  Future<void> load() async {
    final viewer = _viewer;
    if (viewer == null) return;
    final request = ++_request;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final shelf = await source.shelf(
        viewer: viewer,
        viewerId: _viewerId,
        color: _selected,
      );
      if (request != _request) return;
      _shelf = shelf;
    } on Failure catch (failure) {
      if (request != _request) return;
      _error = failure.message;
    } catch (_) {
      if (request != _request) return;
      _error = '가판대를 불러오지 못했어요. 다시 시도해 주세요.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<int> sameColorCount(ServiceDate date, EselPaint color) =>
      source.sameColorCount(date, color);
}
