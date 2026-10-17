import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/features/collections/domain/cover_collection.dart';
import 'package:esel/features/collections/data/collection_source.dart';
import 'package:esel/features/challenges/domain/challenge.dart';
import 'package:esel/features/challenges/data/challenge_source.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/reactions/presentation/controllers/reactions_controller.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';

const today = ServiceDate(2026, 10, 18);
SameColorViewer viewer({bool published = false}) => SameColorViewer(
  today: today,
  candidates: [EselPaint.camel],
  hasPublishedToday: published,
  isMinor: false,
);
CoverDraft draft(
  String id, {
  String owner = 'alice',
  EselPaint color = EselPaint.powder,
}) => CoverDraft(
  id: id,
  ownerId: owner,
  masthead: owner,
  photoPath: 'missing.png',
  color: color,
  faceConfirmed: true,
  updatedAt: today.startsAt,
);

class FailingReactions extends LocalLibrary {
  FailingReactions() : super.inMemory();
  bool fail = true;
  @override
  Future<void> saveReactions(String owner, Map<String, dynamic> data) async {
    if (fail) throw const FileSystemException('test failure');
    await super.saveReactions(owner, data);
  }
}

void main() {
  test('일·주·월 서울 기간: 월/연도/윤년 경계와 종료 미포함', () {
    final leap = CollectionPeriod.at(
      CollectionUnit.month,
      const ServiceDate(2028, 2, 29),
    );
    expect(leap.start, const ServiceDate(2028, 2, 1));
    expect(leap.end, const ServiceDate(2028, 3, 1));
    expect(
      CollectionPeriod.at(
        CollectionUnit.month,
        const ServiceDate(2026, 12, 31),
      ).move(1).start,
      const ServiceDate(2027, 1, 1),
    );
    final week = CollectionPeriod.at(
      CollectionUnit.week,
      const ServiceDate(2027, 1, 3),
    );
    expect(week.start, const ServiceDate(2026, 12, 28));
    expect(week.end, const ServiceDate(2027, 1, 4));
    expect(
      CollectionPeriod.at(CollectionUnit.day, today).end,
      today.addDays(1),
    );
    expect(ServiceDate.of(DateTime.utc(2026, 10, 17, 15)), today);
  });

  test('발행본 삭제·저장소 재시작 후에도 하루 한 호와 누적 호수를 보존한다', () async {
    final dir = Directory.systemTemp.createTempSync('esel-ledger-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final lib = LocalLibrary(dir);
    await lib.load();
    await lib.publish(draft('one'), 'alice', on: today.addDays(-1));
    await lib.publish(draft('two'), 'alice', on: today);
    await lib.delete('one');
    await lib.delete('two');
    final reopened = LocalLibrary(dir);
    await reopened.load();
    expect(reopened.hasPublishedOn('alice', today), isTrue);
    await expectLater(
      reopened.publish(draft('duplicate'), 'alice', on: today),
      throwsFormatException,
    );
    final next = await reopened.publish(
      draft('three'),
      'alice',
      on: today.addDays(1),
    );
    expect(next.issueNumber, 3);
    expect(reopened.publicationCount('alice'), 3);
  });

  test('특집은 공개 필터 후 기간별로 선정하며 계정·이유·삭제·재시작을 보존한다', () async {
    final dir = Directory.systemTemp.createTempSync('esel-curation-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final lib = LocalLibrary(dir);
    await lib.load();
    await lib.publish(draft('mine'), 'alice', on: today);
    await lib.publish(
      draft('locked', owner: 'bob', color: EselPaint.camel),
      'bob',
      on: today,
    );
    await lib.publish(
      draft('past', owner: 'carol'),
      'carol',
      on: today.addDays(-1),
    );
    await lib.save(draft('unpublished', owner: 'dan'));
    await lib.save(
      draft(
        'future',
        owner: 'eve',
      ).copyWith(issueNumber: 1, publishedOn: today.addDays(1).key),
    );
    final source = LocalCollectionSource(() => lib);
    final period = CollectionPeriod.at(CollectionUnit.week, today);
    final available = await source.available('alice', viewer(), period);
    expect(available.map((d) => d.id), ['mine', 'past']);
    await expectLater(
      source.select('alice', viewer(), period, 'locked', '색 활용'),
      throwsFormatException,
    );
    await expectLater(
      source.select('alice', viewer(), period, 'mine', '  '),
      throwsFormatException,
    );
    await source.select('alice', viewer(), period, 'mine', '색 활용');
    await source.select('alice', viewer(), period, 'mine', '다양한 스타일');
    expect(await source.selected('bob', viewer(), period), isEmpty);
    expect(
      await source.selected(
        'alice',
        viewer(),
        CollectionPeriod.at(CollectionUnit.day, today),
      ),
      isEmpty,
    );
    final reopened = LocalLibrary(dir);
    await reopened.load();
    final again = LocalCollectionSource(() => reopened);
    final chosen = await again.selected('alice', viewer(), period);
    expect(chosen, hasLength(1));
    expect(chosen.single.reason, '다양한 스타일');
    await again.remove('alice', period, 'mine');
    expect(reopened.issuesFor('alice'), hasLength(1));
    await again.select('alice', viewer(), period, 'past', '주제에 맞는 착장');
    await reopened.delete('past');
    expect(await again.selected('alice', viewer(), period), isEmpty);
    await again.select('alice', viewer(), period, 'mine', '색 활용');
    await reopened.deleteOwnerData('alice');
    expect(reopened.featuresFor('alice'), isEmpty);
    expect(reopened.reactionsFor('alice'), isEmpty);
    expect(reopened.hasPublishedOn('alice', today), isFalse);
  });

  test('주간 참여자 조회도 공개 필터가 먼저이며 오늘 발행 후 열린다', () async {
    final lib = LocalLibrary.inMemory();
    final challenge = StyleChallenge.forWeek(today).first;
    final issue = await lib.publish(
      draft('bob', owner: 'bob', color: EselPaint.camel),
      'bob',
      on: today,
    );
    await lib.attachChallenge(issue.id, 'bob', challenge, today);
    final source = LocalChallengeSource(() => lib);
    expect(await source.participants('alice', viewer(), challenge.id), isEmpty);
    expect(
      (await source.participants(
        'alice',
        viewer(published: true),
        challenge.id,
      )).single.id,
      'bob',
    );
    expect(
      await source.participants(
        'alice',
        viewer(published: true),
        '${today.key}:invented',
      ),
      isEmpty,
    );
    final topics = {
      for (var i = 0; i < 4; i++)
        StyleChallenge.forWeek(today.addDays(i * 7)).first.topic,
    };
    expect(topics, {'가방으로 포인트', '겹쳐 입기', '데님', '비 오는 날'});
  });

  test('반응 계정 전환·재시작: 구독·좋아요·스크랩·독자 한 줄이 섞이지 않는다', () async {
    final dir = Directory.systemTemp.createTempSync('esel-reactions-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final lib = LocalLibrary(dir);
    await lib.load();
    final reactions = ReactionsController()..bindUser('alice', lib);
    reactions.toggleLike('issue');
    reactions.toggleScrap('issue');
    reactions.toggleSubscription('bob');
    reactions.addReaderLine(
      issueId: 'issue',
      text: '멋진 색 조합',
      authorMasthead: 'alice',
    );
    reactions.bindUser('bob', lib);
    expect(reactions.isLiked('issue'), isFalse);
    expect(reactions.getReaderLines('issue'), isEmpty);
    reactions.bindUser('alice', lib);
    expect(reactions.isLiked('issue'), isTrue);
    await reactions.whenSaved;
    final reopened = LocalLibrary(dir);
    await reopened.load();
    final again = ReactionsController()..bindUser('alice', reopened);
    expect(again.isLiked('issue'), isTrue);
    expect(again.isScrapped('issue'), isTrue);
    expect(again.isSubscribed('bob'), isTrue);
    expect(again.getReaderLines('issue').single.text, '멋진 색 조합');
    again.bindUser(null, reopened);
    expect(again.isLiked('issue'), isFalse);
  });

  test('반응 저장 실패는 재시도 가능하며 원격 특집은 로컬로 전환하지 않는다', () async {
    final lib = FailingReactions();
    final reactions = ReactionsController()..bindUser('alice', lib);
    reactions.toggleLike('issue');
    await reactions.whenSaved;
    expect(reactions.saveError, isNotNull);
    lib.fail = false;
    reactions.retrySave();
    await reactions.whenSaved;
    expect(reactions.saveError, isNull);
    expect(lib.reactionsFor('alice')['likes'], ['issue']);
    await expectLater(
      RemoteCollectionSource().available(
        'alice',
        viewer(),
        CollectionPeriod.at(CollectionUnit.day, today),
      ),
      throwsA(isA<NotImplementedFailure>()),
    );
  });
}
