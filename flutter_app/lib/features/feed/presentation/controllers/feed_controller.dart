import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../../data/sources/feed_source.dart';
import '../../domain/models/feed_page.dart';

export '../../domain/models/feed_page.dart';

/// 표지 피드 상태. 데이터는 [FeedSource](mock 또는 서버)에서만 받는다.
class FeedController extends ChangeNotifier {
  final FeedSource source;

  FeedController(this.source);

  FeedTab _tab = FeedTab.all;
  FeedPage? _page;
  bool _loading = false;
  String? _error;

  SameColorViewer? _viewer;
  bool _signedIn = false;
  Set<String> _subscribed = const {};
  int _request = 0;

  FeedTab get currentTab => _tab;
  FeedPage? get page => _page;
  bool get isLoading => _loading;
  String? get errorMessage => _error;

  /// 보는 사람이 바뀌면(로그인·발행·자정·구독) 다시 받는다.
  void configure({
    required SameColorViewer viewer,
    required bool signedIn,
    required Set<String> subscribedOwnerIds,
  }) {
    final changed =
        _viewer != viewer ||
        _signedIn != signedIn ||
        !setEquals(_subscribed, subscribedOwnerIds);
    _viewer = viewer;
    _signedIn = signedIn;
    _subscribed = Set.of(subscribedOwnerIds);
    if (changed || _page == null) load();
  }

  void switchTab(FeedTab tab) {
    if (_tab == tab) return;
    _tab = tab;
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
      final page = await source.today(
        viewer: viewer,
        signedIn: _signedIn,
        tab: _tab,
        subscribedOwnerIds: _subscribed,
      );
      if (request != _request) return;
      _page = page;
    } on Failure catch (failure) {
      if (request != _request) return;
      _error = failure.message;
    } catch (_) {
      if (request != _request) return;
      _error = '오늘의 표지를 불러오지 못했어요. 다시 시도해 주세요.';
    }
    _loading = false;
    notifyListeners();
  }
}
