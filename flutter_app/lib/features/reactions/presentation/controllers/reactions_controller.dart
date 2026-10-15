import 'package:flutter/foundation.dart';
import '../../domain/models/reaction_state.dart';

class ReactionsController extends ChangeNotifier {
  final Set<String> _likedIssueIds = {};
  final Set<String> _scrappedIssueIds = {};

  /// 구독한 잡지(주인 id). 처음에는 아무것도 구독하지 않았다.
  final Set<String> _subscribedOwners = {};

  final Map<String, List<ReaderLine>> _readerLinesMap = {
    'dana_249': [
      ReaderLine(
        id: 'line_1',
        authorMasthead: 'seul',
        text: '파우더 블루 색감이 오늘 늦여름 하늘이랑 참 잘 어울려요.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
      ),
      ReaderLine(
        id: 'line_2',
        authorMasthead: 'min',
        text: '표지 셔츠 주름 디테일이 멋집니다.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
    ],
  };

  bool isLiked(String issueId) => _likedIssueIds.contains(issueId);
  bool isScrapped(String issueId) => _scrappedIssueIds.contains(issueId);
  bool isSubscribed(String ownerId) => _subscribedOwners.contains(ownerId);
  Set<String> get subscribedOwnerIds => Set.unmodifiable(_subscribedOwners);

  void toggleLike(String issueId) {
    if (_likedIssueIds.contains(issueId)) {
      _likedIssueIds.remove(issueId);
    } else {
      _likedIssueIds.add(issueId);
    }
    notifyListeners();
  }

  void toggleScrap(String issueId) {
    if (_scrappedIssueIds.contains(issueId)) {
      _scrappedIssueIds.remove(issueId);
    } else {
      _scrappedIssueIds.add(issueId);
    }
    notifyListeners();
  }

  void toggleSubscription(String ownerId) {
    if (_subscribedOwners.contains(ownerId)) {
      _subscribedOwners.remove(ownerId);
    } else {
      _subscribedOwners.add(ownerId);
    }
    notifyListeners();
  }

  List<ReaderLine> getReaderLines(String issueId) {
    return _readerLinesMap[issueId] ?? [];
  }

  bool addReaderLine({
    required String issueId,
    required String text,
    required String authorMasthead,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 60) {
      return false;
    }

    final newLine = ReaderLine(
      id: 'line_${DateTime.now().millisecondsSinceEpoch}',
      authorMasthead: authorMasthead,
      text: trimmed,
      createdAt: DateTime.now(),
    );

    final list = _readerLinesMap.putIfAbsent(issueId, () => []);
    list.insert(0, newLine);
    notifyListeners();
    return true;
  }

  OwnerReactionStats getOwnerStats(String issueId) {
    final lines = getReaderLines(issueId).length;
    final isL = isLiked(issueId);
    final isS = isScrapped(issueId);
    return OwnerReactionStats(
      readCount: 142,
      likeCount: 38 + (isL ? 1 : 0),
      scrapCount: 12 + (isS ? 1 : 0),
      readerLineCount: lines,
    );
  }
}
