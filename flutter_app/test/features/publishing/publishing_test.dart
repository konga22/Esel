import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/publishing/presentation/controllers/publishing_controller.dart';
import 'package:esel/features/publishing/domain/rules/publish_rule.dart';

void main() {
  group('DEV-09 Publishing Tests (P04, P03)', () {
    test('publish rule prevents second publish on same day', () {
      final canPublish = PublishRule.canPublishToday(hasPublishedToday: true, isAccountActive: true);
      expect(canPublish, isFalse);

      final nextIssue = PublishRule.calculateNextIssueNumber(currentIssueCount: 249, isPublishingSuccessful: false);
      expect(nextIssue, equals(249));
    });

    test('publishing controller successfully increments issue count when valid', () async {
      final controller = PublishingController();
      final res = await controller.submitPublish(hasPublishedToday: false, currentIssueCount: 249);
      expect(res.success, isTrue);
      expect(res.newIssueCount, equals(250));
    });

    test('publishing controller rejects if already published today', () async {
      final controller = PublishingController();
      final res = await controller.submitPublish(hasPublishedToday: true, currentIssueCount: 250);
      expect(res.success, isFalse);
      expect(controller.errorMessage, isNotNull);
    });
  });
}
