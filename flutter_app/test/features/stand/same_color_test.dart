import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';

void main() {
  group('DEV-02 P01, P02 Same Color Rule Tests', () {
    final covers = ['c1', 'c2', 'c3', 'c4', 'c5'];

    test('unpublished same color room shows 3 previews and hides rest', () {
      final res = SameColorRule.evaluateRoom(
        roomColorKey: 'powder-blue',
        mySelectedColorKey: 'powder-blue',
        hasPublishedToday: false,
        allCoverIdsInRoom: covers,
      );

      expect(res.access, equals(SameColorRoomAccess.preview));
      expect(res.visibleCoverIds.length, equals(3));
      expect(res.hiddenCount, equals(2));
      expect(res.bannerMessage, equals('발행하면 함께 펼쳐집니다'));
    });

    test('published user unlocks full room without hidden counts', () {
      final res = SameColorRule.evaluateRoom(
        roomColorKey: 'powder-blue',
        mySelectedColorKey: 'powder-blue',
        hasPublishedToday: true,
        allCoverIdsInRoom: covers,
      );

      expect(res.access, equals(SameColorRoomAccess.open));
      expect(res.visibleCoverIds.length, equals(5));
      expect(res.hiddenCount, equals(0));
    });

    test('different color room is open even before user publishes today', () {
      final res = SameColorRule.evaluateRoom(
        roomColorKey: 'sage',
        mySelectedColorKey: 'powder-blue',
        hasPublishedToday: false,
        allCoverIdsInRoom: covers,
      );

      expect(res.access, equals(SameColorRoomAccess.open));
      expect(res.visibleCoverIds.length, equals(5));
      expect(res.hiddenCount, equals(0));
    });
  });
}
