import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/twin/domain/rules/twin_rule.dart';

void main() {
  group('DEV-02 P08~P10 Twin Rule Tests', () {
    test('partner photo is concealed until both have posted', () {
      expect(
        TwinRule.canRevealPartnerPhoto(hasUserPosted: true, hasPartnerPosted: false),
        isFalse,
      );
      expect(
        TwinRule.canRevealPartnerPhoto(hasUserPosted: true, hasPartnerPosted: true),
        isTrue,
      );
    });

    test('joint visibility requires mutual consent', () {
      expect(
        TwinRule.canPublishJointIssue(
          visibility: TwinVisibility.jointPublic,
          hasUserConsented: true,
          hasPartnerConsented: false,
        ),
        isFalse,
      );
      expect(
        TwinRule.canPublishJointIssue(
          visibility: TwinVisibility.jointPublic,
          hasUserConsented: true,
          hasPartnerConsented: true,
        ),
        isTrue,
      );
    });

    test('private and solo visibility can complete without joint consent', () {
      expect(
        TwinRule.canPublishJointIssue(
          visibility: TwinVisibility.privateRecord,
          hasUserConsented: true,
          hasPartnerConsented: false,
        ),
        isTrue,
      );
      expect(
        TwinRule.canPublishJointIssue(
          visibility: TwinVisibility.soloPublic,
          hasUserConsented: true,
          hasPartnerConsented: false,
        ),
        isTrue,
      );
    });
  });
}
