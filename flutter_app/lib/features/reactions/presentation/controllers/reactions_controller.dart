import '../../../../core/errors/failures.dart';
import '../../../issue/data/sources/issue_remote_source.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../issue/data/demo_issue_catalog.dart';
import '../../../magazine/data/sources/magazine_remote_source.dart';
import 'package:flutter/foundation.dart';
import '../../../drafts/data/local_library.dart';
import '../../domain/models/reaction_state.dart';

class ReactionsController extends ChangeNotifier {
  final IssueRemoteSource? remote;
  final MagazineRemoteSource? remoteMagazine;
  ReactionsController({this.remote, this.remoteMagazine});
  bool get isRemote => remote != null;
  bool loading = false;
  final Map<String, String?> _lineCursors = {};
  final Map<String, OwnerReactionStats> _stats = {};
  Future<void> Function()? _retry;
  String? _retryOwner;
  void seedSubscription(String key, bool selected) {
    selected ? _subscribedOwners.add(key) : _subscribedOwners.remove(key);
  }

  void seedIssue(PublicIssue issue) {
    if (issue.liked != null) {
      issue.liked!
          ? _likedIssueIds.add(issue.id)
          : _likedIssueIds.remove(issue.id);
    }
    if (issue.scrapped != null) {
      issue.scrapped!
          ? _scrappedIssueIds.add(issue.id)
          : _scrappedIssueIds.remove(issue.id);
    }
  }

  Future<void> _run(Future<void> Function() work) {
    final owner = _owner;
    loading = true;
    saveError = null;
    _retry = work;
    _retryOwner = owner;
    notifyListeners();
    final pending = _pending.then((_) async {
      if (owner != _owner) return;
      try {
        await work();
        if (owner == _owner) {
          saveError = null;
          _retry = null;
        }
      } catch (e) {
        if (owner == _owner) {
          saveError = e is Failure ? e.message : '반응을 저장하지 못했어요. 다시 시도해 주세요.';
        }
      } finally {
        if (owner == _owner) {
          loading = false;
          notifyListeners();
        }
      }
    });
    _pending = pending;
    return pending;
  }

  Future<PublicIssue> loadDetails(
    PublicIssue reference, {
    bool owner = false,
  }) async {
    if (!isRemote) return reference;
    final account = _owner;
    final issue = await remote!.read(reference);
    final lines = await remote!.lines(issue.id);
    final stats = owner ? await remote!.ownerReactions(issue.id) : null;
    if (account != _owner) throw const AuthFailure('계정이 변경됐어요. 다시 열어 주세요.');
    seedIssue(issue);
    _readerLinesMap[issue.id] = lines.items;
    _lineCursors[issue.id] = lines.nextCursor;
    if (stats != null) {
      _stats[issue.id] = OwnerReactionStats(
        readCount: null,
        likeCount: stats.likes,
        scrapCount: stats.scraps,
        readerLineCount: stats.lines,
      );
    }
    notifyListeners();
    return issue;
  }

  Future<PublicIssue> ownIssue(String id) async {
    final account = _owner;
    if (account == null) throw const AuthFailure('로그인이 필요해요.');
    if (isRemote) {
      final value = await remote!.readId(id, ownerId: account);
      if (account != _owner) throw const AuthFailure('계정이 변경됐어요.');
      return value;
    }
    final value = _library
        ?.issuesFor(account)
        .where((v) => v.id == id)
        .firstOrNull;
    if (value == null) throw const NotFoundFailure('캔버스를 찾지 못했어요.');
    return DemoIssueCatalog.fromLocal(value);
  }

  bool hasMoreLines(String id) => _lineCursors[id] != null;
  Future<void> moreLines(String id) => _run(() async {
    final account = _owner;
    final page = await remote!.lines(id, cursor: _lineCursors[id]);
    if (account != _owner) return;
    _readerLinesMap[id] = {
      for (final v in [...getReaderLines(id), ...page.items]) v.id: v,
    }.values.toList();
    _lineCursors[id] = page.nextCursor;
  });
  Future<bool> submitReaderLine({
    required String issueId,
    required String text,
    required String authorMasthead,
  }) async {
    if (!isRemote) {
      return addReaderLine(
        issueId: issueId,
        text: text,
        authorMasthead: authorMasthead,
      );
    }
    if (text.trim().isEmpty || text.trim().runes.length > 60 || loading) {
      return false;
    }
    var saved = false;
    await _run(() async {
      final account = _owner;
      await remote!.addLine(issueId, text);
      if (account != _owner) return;
      saved = true;
      // 저장된 댓글을 재전송하지 않고 조회만 다시 시도한다.
      Future<void> refresh() async {
        final page = await remote!.lines(issueId);
        if (account == _owner) {
          _readerLinesMap[issueId] = page.items;
          _lineCursors[issueId] = page.nextCursor;
        }
      }

      _retry = refresh;
      final lines = await remote!.lines(issueId);
      if (account == _owner) {
        _readerLinesMap[issueId] = lines.items;
        _lineCursors[issueId] = lines.nextCursor;
      }
    });
    return saved;
  }

  LocalLibrary? _library;
  String? _owner;
  String? saveError;
  Future<void> _pending = Future.value();
  final Map<String, Map<String, dynamic>> _cache = {};
  Future<void> get whenSaved => _pending;
  void bindUser(String? owner, LocalLibrary? library) {
    if (_owner == owner && identical(_library, library)) return;
    _stats.clear();
    _lineCursors.clear();
    _retry = null;
    _retryOwner = null;
    loading = false;
    _owner = owner;
    _library = library;
    _likedIssueIds.clear();
    _scrappedIssueIds.clear();
    _subscribedOwners.clear();
    _readerLinesMap.clear();
    saveError = null;
    final data = owner == null
        ? <String, dynamic>{}
        : isRemote
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

  void retrySave() {
    if (isRemote) {
      if (_retryOwner == _owner && _retry != null) _run(_retry!);
    } else {
      _persist();
    }
  }

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
    if (isRemote) {
      if (loading) return;
      final enabled = !isLiked(issueId);
      _run(() async {
        final account = _owner;
        final value = await remote!.setReaction(
          issueId,
          like: true,
          enabled: enabled,
        );
        if (account == _owner) {
          value.liked
              ? _likedIssueIds.add(issueId)
              : _likedIssueIds.remove(issueId);
          value.scrapped
              ? _scrappedIssueIds.add(issueId)
              : _scrappedIssueIds.remove(issueId);
        }
      });
      return;
    }
    if (_likedIssueIds.contains(issueId)) {
      _likedIssueIds.remove(issueId);
    } else {
      _likedIssueIds.add(issueId);
    }
    _persist();
    notifyListeners();
  }

  void toggleScrap(String issueId) {
    if (isRemote) {
      if (loading) return;
      final enabled = !isScrapped(issueId);
      _run(() async {
        final account = _owner;
        final value = await remote!.setReaction(
          issueId,
          like: false,
          enabled: enabled,
        );
        if (account == _owner) {
          value.liked
              ? _likedIssueIds.add(issueId)
              : _likedIssueIds.remove(issueId);
          value.scrapped
              ? _scrappedIssueIds.add(issueId)
              : _scrappedIssueIds.remove(issueId);
        }
      });
      return;
    }
    if (_scrappedIssueIds.contains(issueId)) {
      _scrappedIssueIds.remove(issueId);
    } else {
      _scrappedIssueIds.add(issueId);
    }
    _persist();
    notifyListeners();
  }

  void toggleSubscription(String ownerId) {
    if (isRemote) {
      if (loading) return;
      final enabled = !isSubscribed(ownerId);
      _run(() async {
        final account = _owner;
        final value = await remoteMagazine!.subscribe(ownerId, enabled);
        if (account == _owner) seedSubscription(ownerId, value);
      });
      return;
    }
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
    if (isRemote) return false;
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

  /// 올린 본인에게만 보여 주는 숫자(P18). mock에는 다른 독자가 없어서 이 기기에서
  /// 남긴 반응만 센다(예시 숫자를 지어내지 않는다). 읽은 사람 수는 서버가 생기면 받는다.
  OwnerReactionStats getOwnerStats(String issueId) {
    if (isRemote) {
      return _stats[issueId] ??
          const OwnerReactionStats(
            readCount: 0,
            likeCount: 0,
            scrapCount: 0,
            readerLineCount: 0,
          );
    }
    return OwnerReactionStats(
      readCount: 0,
      likeCount: isLiked(issueId) ? 1 : 0,
      scrapCount: isScrapped(issueId) ? 1 : 0,
      readerLineCount: getReaderLines(issueId).length,
    );
  }
}
