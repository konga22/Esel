import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/features/garments/domain/garment.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/records/data/sources/records_source.dart';
import 'package:esel/features/today/domain/rules/daily_candidates.dart';

void main() {
  const item = Garment(
    id: 'coat-id',
    kind: '코트',
    name: '내 코트',
    note: '오래 입음',
    todayColor: true,
    x: .2,
    y: .7,
  );
  CoverDraft draft(String owner, {String id = 'first'}) => CoverDraft(
    id: id,
    photoPath: 'photo.png',
    masthead: 'artist',
    ownerId: owner,
    faceConfirmed: true,
    updatedAt: DateTime.utc(2026, 10, 18),
    garments: const [item],
  );
  test(
    'DEV-24 optional garment data keeps old drafts readable and rejects invalid tags',
    () {
      final json = draft('a').toJson()..remove('garments');
      expect(CoverDraft.fromJson(json).garments, isEmpty);
      expect(Garment.fromJson(item.toJson()).toJson(), item.toJson());
      for (final value in [
        {...item.toJson(), 'x': 1.1},
        {...item.toJson(), 'y': null},
        {...item.toJson(), 'kind': 'unknown'},
        {...item.toJson(), 'note': 'shop-url'},
      ]) {
        expect(() => Garment.fromJson(value), throwsFormatException);
      }
      expect(item.toJson().keys, isNot(contains('price')));
      expect(item.toJson().keys, isNot(contains('url')));
      expect(
        draft('a').copyWith(garments: const [item, item]).validationError,
        isNotNull,
      );
    },
  );
  test(
    'garment IDs survive restart, re-use, issue deletion and are isolated per account',
    () async {
      final dir = await Directory.systemTemp.createTemp('esel-garments-');
      addTearDown(() => dir.delete(recursive: true));
      final first = LocalLibrary(dir);
      await first.load();
      await first.save(draft('a'));
      await first.publish(draft('a'), 'a', on: const ServiceDate(2026, 10, 17));
      final second = LocalLibrary(dir);
      await second.load();
      expect(second.garmentsFor('a').single.id, item.id);
      expect(second.garmentsFor('b'), isEmpty);
      final reused = item.at(null, null).forColor(false);
      await second.save(draft('a', id: 'second').copyWith(garments: [reused]));
      expect(second.garmentsFor('a'), hasLength(1));
      expect(second.garmentsFor('a').single.x, isNull);
      await second.delete('first');
      expect(second.garmentsFor('a').single.id, item.id);
      await second.deleteOwnerData('a');
      final third = LocalLibrary(dir);
      await third.load();
      expect(third.garmentsFor('a'), isEmpty);
      final stored = jsonDecode(
        await File('${dir.path}/library.json').readAsString(),
      );
      expect(stored['personalRecords']['a'], isNull);
    },
  );
  test(
    'shared color calendar persists restoration and enforces two per month without issuing',
    () async {
      final dir = await Directory.systemTemp.createTemp('esel-records-');
      addTearDown(() => dir.delete(recursive: true));
      var lib = LocalLibrary(dir);
      await lib.load();
      var owner = 'a';
      final clock = ManualServiceClock(DateTime.utc(2026, 10, 18, 3));
      final source = LocalRecordsSource(() => lib, () => owner, clock);
      for (final day in [16, 17]) {
        final date = ServiceDate(2026, 10, day);
        await source.restore(date, DailyCandidates.forDate(date).first);
      }
      expect((await source.month('2026-10')).remaining, 0);
      expect(lib.publicationCount('a'), 0);
      await expectLater(
        source.restore(
          const ServiceDate(2026, 10, 15),
          DailyCandidates.forDate(const ServiceDate(2026, 10, 15)).first,
        ),
        throwsFormatException,
      );
      await expectLater(
        source.restore(clock.today, EselPaint.camel),
        throwsFormatException,
      );
      lib = LocalLibrary(dir);
      await lib.load();
      expect((await source.month('2026-10')).days, hasLength(2));
      owner = 'b';
      expect((await source.month('2026-10')).days, isEmpty);
    },
  );
}
