import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/magazine/domain/rules/privacy_rule.dart';

void main() {
  group('DEV-02 P18 Privacy Rule Tests', () {
    test('exposes reaction counts only to the owner', () {
      expect(
        PrivacyRule.shouldExposeReactionCounts(viewerUserId: 'user_1', ownerUserId: 'user_1'),
        isTrue,
      );
      expect(
        PrivacyRule.shouldExposeReactionCounts(viewerUserId: 'user_2', ownerUserId: 'user_1'),
        isFalse,
      );
    });
  });
}
