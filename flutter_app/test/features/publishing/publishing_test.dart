import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/publishing/domain/rules/publish_rule.dart';

void main() {
  group('DEV-09 P04 하루 한 호, 결호 없는 호수', () {
    test('규칙: 같은 날 두 번째는 거절, 호수는 올리기로만 1씩', () {
      expect(PublishRule.canPublishToday(hasPublishedToday: true), isFalse);
      expect(PublishRule.canPublishToday(hasPublishedToday: false), isTrue);
      expect(PublishRule.nextIssueNumber(0), 1);
      expect(PublishRule.nextIssueNumber(37), 38);
      expect(PublishRule.formatIssueNumber(1), 'Nº 001');
      expect(PublishRule.formatIssueNumber(249), 'Nº 249');
    });

    test('기기 보관함 올리기이 이 규칙을 그대로 따른다', () async {
      final library = LocalLibrary.inMemory();
      addTearDown(library.dispose);
      CoverDraft draft(String id) => CoverDraft(
        id: id,
        photoPath: 'p.png',
        masthead: 'mag',
        faceConfirmed: true,
        updatedAt: DateTime.utc(2026, 10, 15),
      );
      final first = await library.publish(
        draft('a'),
        'owner',
        on: const ServiceDate(2026, 10, 15),
      );
      expect(first.issueNumber, 1);
      await expectLater(
        library.publish(
          draft('b'),
          'owner',
          on: const ServiceDate(2026, 10, 15),
        ),
        throwsFormatException,
      );
      // 저장만 한 초안(확정)은 호수를 올리지 않는다(P03).
      await library.save(draft('c').copyWith(ownerId: 'owner'));
      final second = await library.publish(
        draft('d'),
        'owner',
        on: const ServiceDate(2026, 10, 17),
      );
      expect(second.issueNumber, 2, reason: '날짜가 비어도 호수는 결호 없이');
      expect(library.issuesFor('owner').map((d) => d.issueNumber), [2, 1]);
    });
  });
}
