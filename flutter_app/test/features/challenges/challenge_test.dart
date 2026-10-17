import 'dart:io';
import 'package:esel/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/challenges/domain/challenge.dart';
import 'package:esel/features/challenges/data/challenge_source.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/drafts/data/local_library.dart';

void main() {
  const monday = ServiceDate(2026, 10, 12);
  CoverDraft draft(String id, {String owner = 'alice'}) => CoverDraft(
    id: id,
    ownerId: owner,
    photoPath: 'photo.png',
    masthead: 'alice',
    faceConfirmed: true,
    color: EselPaint.camel,
    updatedAt: monday.startsAt,
  );
  test(
    'Seoul week is Monday inclusive, next Monday exclusive across years',
    () {
      final c = StyleChallenge.forWeek(const ServiceDate(2027, 1, 3)).first;
      expect(c.start, const ServiceDate(2026, 12, 28));
      expect(c.isOpen(const ServiceDate(2027, 1, 3)), isTrue);
      expect(c.isOpen(const ServiceDate(2027, 1, 4)), isFalse);
      expect(StyleChallenge.resolve('invented'), isNull);
    },
  );
  test('old JSON without participation fields remains readable', () {
    final json = draft('old').toJson()
      ..remove('challengeId')
      ..remove('previousIssueId');
    expect(CoverDraft.fromJson(json).challengeId, isNull);
  });
  test(
    'missing photos can be detected without discarding the stored draft',
    () async {
      final lib = LocalLibrary.inMemory();
      final d = draft('missing');
      await lib.save(d);
      expect(await lib.photoExists(d.photoPath), isFalse);
      expect(await lib.photoExists('memory:deleted'), isFalse);
      expect(lib.drafts.single.id, d.id);
    },
  );
  test(
    'existing today issue attaches idempotently, never increments issues',
    () async {
      final lib = LocalLibrary.inMemory();
      final c = StyleChallenge.forWeek(monday).first;
      final issue = await lib.publish(draft('one'), 'alice', on: monday);
      await lib.attachChallenge(issue.id, 'alice', c, monday);
      await lib.attachChallenge(issue.id, 'alice', c, monday);
      expect(lib.issuesFor('alice').length, 1);
      expect(lib.issuesFor('alice').single.issueNumber, 1);
      await expectLater(
        lib.publish(draft('two'), 'alice', on: monday),
        throwsFormatException,
      );
      await expectLater(
        lib.attachChallenge(issue.id, 'bob', c, monday),
        throwsFormatException,
      );
      await expectLater(
        lib.attachChallenge(issue.id, 'alice', c, monday.addDays(7)),
        throwsFormatException,
      );
    },
  );
  test(
    'restyle requires own past publication, deletion removes only connection',
    () async {
      final lib = LocalLibrary.inMemory();
      final c = StyleChallenge.forWeek(monday).last;
      final previous = await lib.publish(
        draft('past'),
        'alice',
        on: monday.addDays(-1),
      );
      final today = await lib.publish(draft('today'), 'alice', on: monday);
      await expectLater(
        lib.attachChallenge(today.id, 'alice', c, monday),
        throwsFormatException,
      );
      await expectLater(
        lib.attachChallenge(today.id, 'alice', c, monday, previousId: today.id),
        throwsFormatException,
      );
      await lib.attachChallenge(
        today.id,
        'alice',
        c,
        monday,
        previousId: previous.id,
      );
      await lib.delete(previous.id);
      expect(lib.issuesFor('alice').single.id, today.id);
      expect(lib.issuesFor('alice').single.challengeId, isNull);
    },
  );
  test(
    'draft participation validates again at publication, not at editor entry',
    () async {
      final lib = LocalLibrary.inMemory();
      final c = StyleChallenge.forWeek(monday).first;
      final d = draft('pending').copyWith(challengeId: c.id);
      await lib.save(d);
      await expectLater(
        lib.publish(d, 'alice', on: monday.addDays(7)),
        throwsFormatException,
      );
      expect(lib.issuesFor('alice'), isEmpty);
      expect(lib.drafts.single.issueNumber, 0);
    },
  );
  test(
    'restart preserves attachment; detach and account deletion persist',
    () async {
      final dir = await Directory.systemTemp.createTemp('esel-challenges-');
      addTearDown(() => dir.delete(recursive: true));
      final a = LocalLibrary(dir);
      final c = StyleChallenge.forWeek(monday).first;
      final issue = await a.publish(draft('saved'), 'alice', on: monday);
      await a.attachChallenge(issue.id, 'alice', c, monday);
      final b = LocalLibrary(dir);
      await b.load();
      expect(b.issuesFor('alice').single.challengeId, c.id);
      final source = LocalChallengeSource(() => b);
      expect((await source.mine('bob')), isEmpty);
      await b.detachChallenge(issue.id, 'alice');
      final reloaded = LocalLibrary(dir);
      await reloaded.load();
      expect(reloaded.issuesFor('alice').single.challengeId, isNull);
      await reloaded.deleteOwnerData('alice');
      expect(await LocalChallengeSource(() => reloaded).mine('alice'), isEmpty);
    },
  );
  test('remote source never silently falls back to local', () async {
    await expectLater(
      RemoteChallengeSource().current(monday),
      throwsA(isA<NotImplementedFailure>()),
    );
    await expectLater(
      RemoteChallengeSource().mine('alice'),
      throwsA(isA<NotImplementedFailure>()),
    );
  });
  test('restyle cannot link another account or an unpublished draft', () async {
    final lib = LocalLibrary.inMemory();
    await lib.save(draft('unfinished'));
    await lib.publish(
      draft('foreign', owner: 'bob'),
      'bob',
      on: monday.addDays(-1),
    );
    final today = await lib.publish(draft('current'), 'alice', on: monday);
    final c = StyleChallenge.forWeek(monday).last;
    for (final previous in ['unfinished', 'foreign']) {
      await expectLater(
        lib.attachChallenge(today.id, 'alice', c, monday, previousId: previous),
        throwsFormatException,
      );
    }
    expect(lib.issuesFor('alice').single.challengeId, isNull);
  });
  test(
    'publication cannot overwrite a foreign draft or an existing issue ID',
    () async {
      final lib = LocalLibrary.inMemory();
      await lib.save(draft('foreign', owner: 'bob'));
      await expectLater(
        lib.publish(draft('foreign'), 'alice', on: monday),
        throwsFormatException,
      );
      final issue = await lib.publish(draft('first'), 'alice', on: monday);
      await expectLater(
        lib.publish(issue, 'alice', on: monday.addDays(1)),
        throwsFormatException,
      );
      expect(lib.issuesFor('alice').single.publishedOn, monday.key);
      expect(lib.drafts.where((d) => d.ownerId == 'bob'), hasLength(1));
    },
  );
}
