import '../../../issue/domain/models/public_issue.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/time/service_date.dart';
import '../../data/sources/stand_source.dart';
import '../../domain/models/stand_shelf.dart';
import '../../domain/rules/same_color_rule.dart';

export '../../domain/models/stand_shelf.dart';

/// 팔레트 상태. 데이터는 [StandSource](mock 또는 서버)에서만 받는다.
class StandController extends ChangeNotifier {
  final StandSource source;

  StandController(this.source);

  PaletteTab tab = PaletteTab.recommended;
  Set<String> subscriptions = const {};
  EselPaint? preferredColor;
  List<PublicIssue> get tiles {
    var values = _shelf?.items ?? const <PublicIssue>[];
    if (tab == PaletteTab.colors) return values;
    final people = <String, PublicIssue>{};
    for (final issue in values) {
      if (tab == PaletteTab.subscriptions &&
          !subscriptions.contains(issue.ownerId)) {
        continue;
      }
      if (tab == PaletteTab.recommended &&
          (issue.ownerId == _viewerId ||
              subscriptions.contains(issue.ownerId))) {
        continue;
      }
      final previous = people[issue.ownerId];
      if (previous == null || issue.publishedAt.isAfter(previous.publishedAt)) {
        people[issue.ownerId] = issue;
      }
    }
    return people.values.toList()..sort((a, b) {
      final byColor = (b.color == preferredColor ? 1 : 0).compareTo(
        a.color == preferredColor ? 1 : 0,
      );
      return byColor != 0 ? byColor : b.publishedAt.compareTo(a.publishedAt);
    });
  }

  void selectTab(PaletteTab value) {
    tab = value;
    if (value != PaletteTab.colors) _selected = null;
    load();
  }

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

  /// 보는 사람이 바뀌면(로그인·올리기·자정) 다시 받는다.
  void configure({required SameColorViewer viewer, String? viewerId}) {
    final changed = _viewer != viewer || _viewerId != viewerId;
    _viewer = viewer;
    _viewerId = viewerId;
    if (changed || (_shelf == null && !_loading && _error == null)) load();
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
    _shelf = null;
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
      _error = '팔레트를 불러오지 못했어요. 다시 시도해 주세요.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<int> sameColorCount(ServiceDate date, EselPaint color) =>
      source.sameColorCount(date, color);
}
