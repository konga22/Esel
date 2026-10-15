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
        faceWidth: .2,
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

  test('탈퇴하면 그 사람의 호·초안·사진, 내보낸 이미지, 쓰지 않는 사진까지 지운다', () async {
    Future<String> photo(String name) async {
      final file = File('${directory.path}/$name.png');
      await file.writeAsBytes([1, 2, 3]);
      return file.path;
    }

    final aIssue = await photo('a-issue');
    final aDraft = await photo('a-draft');
    final bIssue = await photo('b-issue');
    final abandoned = await photo('abandoned');
    final exports = Directory('${directory.path}/exports')..createSync();
    File('${exports.path}/esel-1.png').writeAsBytesSync([1]);
    // 사진첩 원본(보관함 밖)은 지우지 않는다.
    final outside = await Directory.systemTemp.createTemp('esel-album-');
    final original = File('${outside.path}/original.jpg')
      ..writeAsBytesSync([9]);

    await library.publish(
      draft('a1').copyWith(photoPath: aIssue),
      'owner-a',
      on: const ServiceDate(2026, 10, 14),
    );
    await library.save(
      draft('a2').copyWith(photoPath: aDraft, ownerId: 'owner-a'),
    );
    await library.save(
      draft('a3').copyWith(photoPath: original.path, ownerId: 'owner-a'),
    );
    await library.publish(
      draft('b1').copyWith(photoPath: bIssue),
      'owner-b',
      on: const ServiceDate(2026, 10, 14),
    );

    await library.deleteOwnerData('owner-a');

    expect(library.drafts.map((d) => d.ownerId), everyElement('owner-b'));
    expect(File(aIssue).existsSync(), isFalse);
    expect(File(aDraft).existsSync(), isFalse);
    expect(File(abandoned).existsSync(), isFalse);
    expect(exports.existsSync(), isFalse);
    expect(File(bIssue).existsSync(), isTrue);
    expect(original.existsSync(), isTrue);
    final reopened = LocalLibrary(directory);
    await reopened.load();
    expect(reopened.issuesFor('owner-a'), isEmpty);
    expect(reopened.issuesFor('owner-b'), hasLength(1));
    reopened.dispose();
    await outside.delete(recursive: true);
  });

  test('초안을 지우면 그 초안만 쓰던 사진도 지운다', () async {
    final file = File('${directory.path}/only.png')..writeAsBytesSync([1]);
    final shared = File('${directory.path}/shared.png')..writeAsBytesSync([1]);
    await library.save(draft('x').copyWith(photoPath: file.path));
    await library.save(draft('y').copyWith(photoPath: shared.path));
    await library.save(draft('z').copyWith(photoPath: shared.path));
    await library.delete('x');
    await library.delete('y');
    expect(file.existsSync(), isFalse);
    expect(shared.existsSync(), isTrue, reason: 'z가 아직 쓴다');
  });
}
