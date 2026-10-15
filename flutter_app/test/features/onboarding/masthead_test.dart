import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/onboarding/domain/rules/masthead_rule.dart';

void main() {
  group('DEV-02 P14 Masthead Rule Tests', () {
    test('accepts valid 2 to 10 lowercase english alphabets', () {
      expect(MastheadRule.isValid('esel'), isTrue);
      expect(MastheadRule.isValid('dana'), isTrue);
      expect(MastheadRule.isValid('ab'), isTrue);
      expect(MastheadRule.isValid('abcdefghij'), isTrue);
    });

    test('rejects less than 2 or greater than 10 chars', () {
      expect(MastheadRule.isValid(''), isFalse);
      expect(MastheadRule.isValid('a'), isFalse);
      expect(MastheadRule.isValid('abcdefghijk'), isFalse);
    });

    test('rejects uppercase, korean, spaces, and numbers', () {
      expect(MastheadRule.isValid('Esel'), isFalse);
      expect(MastheadRule.isValid('esel1'), isFalse);
      expect(MastheadRule.isValid('es el'), isFalse);
      expect(MastheadRule.isValid('에셀'), isFalse);
    });

    test('sanitizes input properly', () {
      expect(MastheadRule.sanitize('Esel 2026!'), equals('esel'));
      expect(MastheadRule.sanitize('VeryLongMastheadNameExceedingLimit'), equals('verylongma'));
    });
  });
}
