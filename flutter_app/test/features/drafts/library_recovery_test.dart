import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/drafts/presentation/draft_library_screen.dart';

void main() {
  test(
    'broken main and backup files open read-only and never overwrite existing bytes',
    () async {
      final dir = await Directory.systemTemp.createTemp('esel-review-storage-');
      addTearDown(() => dir.delete(recursive: true));
      final folder = Directory('${dir.path}/${LocalLibrary.serverFolder}');
      await folder.create();
      final index = File('${folder.path}/library.json'),
          backup = File('${folder.path}/library.backup.json');
      await index.writeAsString('broken original');
      await backup.writeAsString('broken backup');
      final lib = await LocalLibrary.open(root: dir);
      addTearDown(lib.dispose);
      expect(lib.available, isFalse);
      expect(lib.loadError, isNotNull);
      await expectLater(lib.settings(motion: true), throwsFormatException);
      expect(await index.readAsString(), 'broken original');
      expect(await backup.readAsString(), 'broken backup');
      await index.writeAsString(jsonEncode({'version': 1, 'drafts': []}));
      await lib.loadForStartup();
      expect(lib.available, isTrue);
      await lib.settings(motion: true);
      expect(lib.reduceMotion, isTrue);
    },
  );
  testWidgets(
    'draft list isolates owners, preserves legacy files and confirms deletion',
    (tester) async {
      final lib = LocalLibrary.inMemory();
      addTearDown(lib.dispose);
      for (final owner in ['a', 'b', '']) {
        await lib.save(
          CoverDraft(
            id: 'draft-$owner',
            ownerId: owner,
            photoPath: 'photo.png',
            masthead: 'artist',
            faceConfirmed: true,
            caption: 'owner-$owner',
            updatedAt: DateTime.utc(2026, 10, 18),
          ),
        );
      }
      await tester.pumpWidget(
        MaterialApp(
          home: DraftLibraryScreen(
            library: lib,
            ownerId: 'a',
            clock: ManualServiceClock(DateTime.utc(2026, 10, 18)),
            onEdit: (_) {},
          ),
        ),
      );
      expect(find.byKey(const ValueKey('draft-draft-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('draft-draft-b')), findsNothing);
      expect(find.textContaining('이전 기기 자료 1개'), findsOneWidget);
      await tester.tap(find.byTooltip('초안 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(lib.drafts, hasLength(3));
      await tester.tap(find.byTooltip('초안 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('초안 삭제'));
      await tester.pumpAndSettle();
      expect(lib.drafts.map((v) => v.ownerId), containsAll(['b', '']));
      expect(lib.drafts.any((v) => v.ownerId == 'a'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
