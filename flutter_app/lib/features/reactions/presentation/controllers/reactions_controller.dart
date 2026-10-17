import 'package:flutter/foundation.dart';
import '../../../drafts/data/local_library.dart';
import '../../domain/models/reaction_state.dart';

class ReactionsController extends ChangeNotifier {
  LocalLibrary? _library;
  String? _owner;
  String? saveError;
  Future<void> _pending = Future.value();
  final Map<String, Map<String, dynamic>> _cache = {};
  Future<void> get whenSaved => _pending;
  void bindUser(String? owner, LocalLibrary? library) {
    if (_owner == owner && identical(_library, library)) return;
    _owner = owner;
    _library = library;
    _likedIssueIds.clear();
    _scrappedIssueIds.clear();
    _subscribedOwners.clear();
    _readerLinesMap.clear();
    saveError = null;
    final data = owner == null
        ? <String, dynamic>{}
        : _cache[owner] ?? library?.reactionsFor(owner) ?? {};
    _likedIssueIds.addAll((data['likes'] as List? ?? []).cast<String>());
    _scrappedIssueIds.addAll((data['scraps'] as List? ?? []).cast<String>());
    _subscribedOwners.addAll(
      (data['subscriptions'] as List? ?? []).cast<String>(),
    );
    for (final entry in (data['lines'] as Map? ?? {}).entries) {
      _readerLinesMap[entry.key as String] = (entry.value as List)
          .map((e) => ReaderLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    notifyListeners();
  }

  void _persist() {
    final owner = _owner, library = _library;
    if (owner == null || library == null) return;
    final data = {
      'likes': _likedIssueIds.toList(),
      'scraps': _scrappedIssueIds.toList(),
      'subscriptions': _subscribedOwners.toList(),
      'lines': {
        for (final e in _readerLinesMap.entries)
          e.key: e.value.map((v) => v.toJson()).toList(),
      },
    };
    _cache[owner] = data;
    _pending = library
        .saveReactions(owner, data)
        .then((_) {
          if (_owner == owner) {
            saveError = null;
            notifyListeners();
          }
        })
        .catchError((Object _) {
          if (_owner == owner) {
            saveError = '반응을 저장하지 못했어요. 다시 저장해 주세요.';
            notifyListeners();
          }
        });
  }

  void retrySave() => _persist();
  void forgetOwner(String owner) {
    _cache.remove(owner);
    if (_owner == owner) bindUser(null, _library);
  }

  final Set<String> _likedIssueIds = {};
  final Set<String> _scrappedIssueIds = {};

  /// 구독한 잡지(주인 id). 처음에는 아무것도 구독하지 않았다.
  final Set<String> _subscribedOwners = {};

  final Map<String, List<ReaderLine>> _readerLinesMap = {};

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
    _persist();
    notifyListeners();
  }

  void toggleScrap(String issueId) {
    if (_scrappedIssueIds.contains(issueId)) {
      _scrappedIssueIds.remove(issueId);
    } else {
      _scrappedIssueIds.add(issueId);
    }
    _persist();
    notifyListeners();
  }

  void toggleSubscription(String ownerId) {
    if (_subscribedOwners.contains(ownerId)) {
      _subscribedOwners.remove(ownerId);
    } else {
      _subscribedOwners.add(ownerId);
    }
    _persist();
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
    _persist();
    notifyListeners();
    return true;
  }

  /// 발행한 본인에게만 보여 주는 숫자(P18). mock에는 다른 독자가 없어서 이 기기에서
  /// 남긴 반응만 센다(예시 숫자를 지어내지 않는다). 읽은 사람 수는 서버가 생기면 받는다.
  OwnerReactionStats getOwnerStats(String issueId) {
    return OwnerReactionStats(
      readCount: 0,
      likeCount: isLiked(issueId) ? 1 : 0,
      scrapCount: isScrapped(issueId) ? 1 : 0,
      readerLineCount: getReaderLines(issueId).length,
    );
  }
}
