import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';
import 'package:esel/features/today/presentation/controllers/today_controller.dart';
import 'package:esel/features/twin/domain/rules/twin_rule.dart';
import 'package:esel/features/twin/presentation/controllers/twin_controller.dart';

void main() {
  group('DEV-02 P08~P10 Twin Rule Tests', () {
    test('partner photo is concealed until both have posted', () {
      expect(
        TwinRule.canRevealPartnerPhoto(
          hasUserPosted: true,
          hasPartnerPosted: false,
        ),
        isFalse,
      );
      expect(
        TwinRule.canRevealPartnerPhoto(
          hasUserPosted: true,
          hasPartnerPosted: true,
        ),
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

    test('컨트롤러: 상대 표지는 둘 다 게시한 뒤에만 보인다(P08)', () {
      final twin = TwinController()..startTwinWith('elin');
      expect(twin.visiblePartnerPhoto, isNull);
      twin.chooseColor(EselPaint.sage);
      twin.postMyCover();
      expect(twin.stage, TwinStage.waitingForPartner);
      expect(twin.visiblePartnerPhoto, isNull);
      twin.partnerPosted();
      expect(twin.stage, TwinStage.revealed);
      expect(twin.visiblePartnerPhoto, isNotNull);
    });

    test('트윈 게시는 개인 호수·오늘 올리기·같은 색 잠금에 닿지 않는다(P09)', () {
      final today = TodayController(
        clock: ManualServiceClock(DateTime.utc(2026, 9, 6, 3)),
      )..library = LocalLibrary.inMemory();
      today.bindUser(ownerId: 'owner');
      final twin = TwinController()..startTwinWith('elin');
      twin
        ..chooseColor(today.candidates.first)
        ..postMyCover()
        ..partnerPosted();
      expect(today.hasPublishedToday, isFalse);
      expect(today.issueCount, 0);
      expect(
        SameColorRule.isLockedToday(today.candidates.first, today.viewer),
        isTrue,
      );
    });
  });
}
