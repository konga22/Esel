import '../../drafts/data/local_library.dart';
import '../../drafts/domain/cover_draft.dart';
import '../../../core/time/service_date.dart';
import '../../../core/errors/failures.dart';
import '../domain/challenge.dart';
import '../../stand/domain/rules/same_color_rule.dart';
import '../../issue/domain/rules/local_publication_access.dart';

abstract class ChallengeSource {
  Future<List<StyleChallenge>> current(ServiceDate today);
  Future<List<CoverDraft>> mine(String ownerId);
  Future<void> attach(
    String ownerId,
    String issueId,
    StyleChallenge challenge,
    ServiceDate today, {
    String? previousId,
  });
  Future<void> detach(String ownerId, String issueId);
  Future<List<CoverDraft>> participants(
    String ownerId,
    SameColorViewer viewer,
    String challengeId,
  );
}

/// Only this account's local publications. This is not a simulated public feed:
/// no other account, demo person, hidden ID or photograph is returned.
class LocalChallengeSource implements ChallengeSource {
  final LocalLibrary? Function() library;
  LocalChallengeSource(this.library);
  LocalLibrary get _store =>
      library() ?? (throw const FormatException('보관함을 열지 못했어요. 다시 시도해 주세요.'));
  @override
  Future<List<StyleChallenge>> current(ServiceDate today) async =>
      StyleChallenge.forWeek(today);
  @override
  Future<List<CoverDraft>> mine(String ownerId) async =>
      _store.issuesFor(ownerId).where((i) => i.challengeId != null).toList();
  @override
  Future<void> attach(
    String ownerId,
    String issueId,
    StyleChallenge challenge,
    ServiceDate today, {
    String? previousId,
  }) => _store.attachChallenge(
    issueId,
    ownerId,
    challenge,
    today,
    previousId: previousId,
  );
  @override
  Future<void> detach(String ownerId, String issueId) =>
      _store.detachChallenge(issueId, ownerId);
  @override
  Future<List<CoverDraft>> participants(
    String ownerId,
    SameColorViewer viewer,
    String challengeId,
  ) async => visibleLocalPublications(
    _store.drafts,
    viewer,
    ownerId,
  ).where((d) => d.challengeId == challengeId).toList();
}

/// Server handoff point. No unagreed URL or silent local fallback.
class RemoteChallengeSource implements ChallengeSource {
  Never _pending() =>
      throw const NotImplementedFailure('서버 콘텐츠는 아직 연결하지 않았어요.');
  @override
  Future<List<StyleChallenge>> current(ServiceDate today) async => _pending();
  @override
  Future<List<CoverDraft>> mine(String ownerId) async => _pending();
  @override
  Future<void> attach(
    String ownerId,
    String issueId,
    StyleChallenge challenge,
    ServiceDate today, {
    String? previousId,
  }) async => _pending();
  @override
  Future<void> detach(String ownerId, String issueId) async => _pending();
  @override
  Future<List<CoverDraft>> participants(
    String ownerId,
    SameColorViewer viewer,
    String challengeId,
  ) async => _pending();
}
