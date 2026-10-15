import 'dart:convert';
import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/media/domain/models/face_layout_mode.dart';

void main() {
  late Directory directory;
  late LocalLibrary library;
  CoverDraft draft(String id) => CoverDraft(
    id: id,
    photoPath: 'photo.png',
    masthead: 'esel',
    caption: '오늘의 옷',
    faceConfirmed: true,
    updatedAt: DateTime(2026, 10, 13),
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('esel-library-test-');
    library = LocalLibrary(directory);
    await library.load();
  });
  tearDown(() async {
    library.dispose();
    await directory.delete(recursive: true);
  });
  test('save, edit and reload retain one complete composed draft', () async {
    await library.save(draft('a'));
    await library.save(
      draft('a').copyWith(
        faceMode: FaceLayoutMode.paintStroke,
        faceX: .7,
        maskSize: .6,
        caption: '수정',
      ),
    );
    final reopened = LocalLibrary(directory);
    await reopened.load();
    expect(reopened.drafts, hasLength(1));
    expect(reopened.drafts.single.caption, '수정');
    expect(reopened.drafts.single.faceMode, FaceLayoutMode.paintStroke);
    expect(reopened.drafts.single.faceX, .7);
    reopened.dispose();
  });
  test(
    'queued writes and settings survive reopening; delete is persistent',
    () async {
      await Future.wait([
        library.save(draft('a')),
        library.save(draft('b')),
        library.settings(
          motion: true,
          transparency: true,
          text: true,
          grid: false,
        ),
      ]);
      await library.delete('a');
      final reopened = LocalLibrary(directory);
      await reopened.load();
      expect(reopened.drafts.map((d) => d.id), ['b']);
      expect(
        reopened.reduceMotion &&
            reopened.reduceTransparency &&
            reopened.largeText,
        isTrue,
      );
      expect(reopened.gridView, isFalse);
      reopened.dispose();
    },
  );
  test('corrupt index recovers backup and can save again', () async {
    await library.save(draft('a'));
    await library.save(draft('b'));
    await File('${directory.path}/library.json').writeAsString('{broken');
    final recovered = LocalLibrary(directory);
    await recovered.load();
    expect(recovered.recoveryNotice, isNotNull);
    expect(recovered.drafts.single.id, 'a');
    await recovered.save(draft('c'));
    final reopened = LocalLibrary(directory);
    await reopened.load();
    expect(reopened.drafts.map((d) => d.id), ['c', 'a']);
    recovered.dispose();
    reopened.dispose();
  });
  test(
    'failed disk write rolls back memory and queue remains usable',
    () async {
      await library.save(draft('a'));
      final blocker = Directory('${directory.path}/library.next.json');
      await blocker.create();
      await expectLater(
        library.save(draft('b')),
        throwsA(isA<FileSystemException>()),
      );
      expect(library.drafts.single.id, 'a');
      await blocker.delete();
      await library.save(draft('c'));
      expect(library.drafts.map((d) => d.id), ['c', 'a']);
    },
  );
  test(
    'validates required photo, masthead, face and 40 visible characters',
    () {
      expect(draft('a').copyWith(photoPath: '').validationError, isNotNull);
      expect(draft('a').copyWith(masthead: 'A').validationError, isNotNull);
      expect(
        draft('a').copyWith(faceConfirmed: false).validationError,
        isNotNull,
      );
      expect(
        draft(
          'a',
        ).copyWith(caption: List.filled(40, '👨‍👩‍👧').join()).validationError,
        isNull,
      );
      expect(
        draft(
          'a',
        ).copyWith(caption: List.filled(41, '가').join()).validationError,
        isNotNull,
      );
      expect(
        () => library.save(draft('a').copyWith(faceConfirmed: false)),
        throwsFormatException,
      );
    },
  );
  test('non-image import rejects without altering original', () async {
    final source = File('${directory.path}/invalid.txt');
    await source.writeAsString('not a photo');
    await expectLater(library.importPhoto(source.path), throwsFormatException);
    expect(await source.readAsString(), 'not a photo');
    expect(library.drafts, isEmpty);
  });
  test(
    'local publication is persistent, rejects repeat day and keeps consecutive issues per owner',
    () async {
      final first = await library.publish(
        draft('first'),
        'owner-a',
        on: const ServiceDate(2026, 10, 14),
      );
      expect(first.issueNumber, 1);
      await expectLater(
        library.publish(
          draft('duplicate'),
          'owner-a',
          on: const ServiceDate(2026, 10, 14),
        ),
        throwsFormatException,
      );
      final second = await library.publish(
        draft('second'),
        'owner-a',
        on: const ServiceDate(2026, 10, 15),
      );
      expect(second.issueNumber, 2);
      await library.publish(
        draft('other'),
        'owner-b',
        on: const ServiceDate(2026, 10, 14),
      );
      final reopened = LocalLibrary(directory);
      await reopened.load();
      expect(reopened.issuesFor('owner-a').map((d) => d.issueNumber), [2, 1]);
      expect(reopened.issuesFor('owner-b').single.issueNumber, 1);
      reopened.dispose();
    },
  );

  test(
    'in-memory library (web) keeps photo, draft and issue without files',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final memory = LocalLibrary.inMemory();
      addTearDown(memory.dispose);
      await memory.load();
      expect(memory.persistent, isFalse);
      final onePixelPng = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      );
      final path = await memory.importPhotoBytes(onePixelPng);
      expect(path, startsWith(memoryPhotoPrefix));
      expect(localPhotoProvider(path), isA<MemoryImage>());
      await memory.save(draft('m').copyWith(photoPath: path));
      final issue = await memory.publish(
        memory.drafts.single,
        'owner',
        on: const ServiceDate(2026, 10, 15),
      );
      expect(issue.issueNumber, 1);
      expect(memory.issuesFor('owner').single.photoPath, path);
    },
  );
}
