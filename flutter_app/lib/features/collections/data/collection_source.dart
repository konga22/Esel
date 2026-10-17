import '../../../core/errors/failures.dart';
import '../../drafts/data/local_library.dart';
import '../../drafts/domain/cover_draft.dart';
import '../../issue/domain/rules/local_publication_access.dart';
import '../../stand/domain/rules/same_color_rule.dart';
import '../domain/cover_collection.dart';

abstract class CollectionSource {
  Future<List<CoverDraft>> available(
    String owner,
    SameColorViewer viewer,
    CollectionPeriod period,
  );
  Future<List<FeaturedCover>> selected(
    String owner,
    SameColorViewer viewer,
    CollectionPeriod period,
  );
  Future<void> select(
    String owner,
    SameColorViewer viewer,
    CollectionPeriod period,
    String issueId,
    String reason,
  );
  Future<void> remove(String owner, CollectionPeriod period, String issueId);
}

/// 로컬 편집 권한은 로그인한 본인의 특집에만 적용. 서버 운영자 권한으로 간주하지 않는다.
class LocalCollectionSource implements CollectionSource {
  final LocalLibrary? Function() library;
  LocalCollectionSource(this.library);
  LocalLibrary get _store =>
      library() ?? (throw const FormatException('보관함을 열지 못했어요.'));
  @override
  Future<List<CoverDraft>> available(
    String owner,
    SameColorViewer viewer,
    CollectionPeriod period,
  ) async {
    if (owner.isEmpty) throw const FormatException('로그인이 필요해요.');
    return visibleLocalPublications(
      _store.drafts,
      viewer,
      owner,
    ).where(period.contains).toList();
  }

  @override
  Future<List<FeaturedCover>> selected(
    String owner,
    SameColorViewer viewer,
    CollectionPeriod period,
  ) async {
    final choices = (_store.featuresFor(owner)[period.key] as List? ?? []);
    final availableCovers = await available(owner, viewer, period);
    return [
      for (final issue in availableCovers)
        for (final entry in choices)
          if ((entry as Map)['issueId'] == issue.id)
            FeaturedCover(issue, entry['reason'] as String),
    ];
  }

  @override
  Future<void> select(
    String owner,
    SameColorViewer viewer,
    CollectionPeriod period,
    String issueId,
    String reason,
  ) async {
    final text = validateSelectionReason(reason);
    final issues = await available(owner, viewer, period);
    if (!issues.any((issue) => issue.id == issueId)) {
      throw const FormatException('이 기간에 공개된 발행 표지만 선정할 수 있어요.');
    }
    await _store.selectFeature(owner, period.key, issueId, text);
  }

  @override
  Future<void> remove(String owner, CollectionPeriod period, String issueId) =>
      _store.selectFeature(owner, period.key, issueId, null);
}

class RemoteCollectionSource implements CollectionSource {
  Never _pending() =>
      throw const NotImplementedFailure('표지 특집 서버는 아직 연결하지 않았어요.');
  @override
  Future<List<CoverDraft>> available(
    String owner,
    SameColorViewer viewer,
    CollectionPeriod period,
  ) async => _pending();
  @override
  Future<List<FeaturedCover>> selected(
    String owner,
    SameColorViewer viewer,
    CollectionPeriod period,
  ) async => _pending();
  @override
  Future<void> select(
    String owner,
    SameColorViewer viewer,
    CollectionPeriod period,
    String issueId,
    String reason,
  ) async => _pending();
  @override
  Future<void> remove(
    String owner,
    CollectionPeriod period,
    String issueId,
  ) async => _pending();
}
