import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/drafts/presentation/cover_editor_screen.dart';
import 'package:esel/features/media/presentation/cover_preview.dart';

void main() {
  for (final accept in [false, true]) {
    testWidgets(
      'Android lost photo ${accept ? 'requires confirmation before applying' : 'cancel preserves draft'}',
      (tester) async {
        tester.view.physicalSize = const Size(480, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const channel = MethodChannel('plugins.flutter.io/image_picker');
        var retrieved = 0;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'retrieve') {
              retrieved++;
              return {
                'type': 'image',
                'path': File('assets/demo/blue-city.jpg').absolute.path,
                'pathList': [File('assets/demo/blue-city.jpg').absolute.path],
              };
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        final lib = LocalLibrary.inMemory();
        addTearDown(lib.dispose);
        final initial = CoverDraft(
          id: 'draft',
          ownerId: 'a',
          photoPath: 'assets/demo/blue-city.jpg',
          masthead: 'artist',
          caption: 'keep me',
          faceConfirmed: true,
          updatedAt: DateTime.utc(2026, 10, 18),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: CoverEditorScreen(library: lib, initial: initial),
          ),
        );
        await tester.pumpAndSettle();
        expect(retrieved, 1);
        expect(find.text('중단된 사진 선택을 찾았어요'), findsOneWidget);
        await tester.tap(find.text(accept ? '사진 사용' : '취소'));
        await tester.pumpAndSettle();
        if (accept) {
          for (var i = 0; i < 20; i++) {
            if (tester
                .widget<CoverPreview>(find.byType(CoverPreview))
                .draft
                .photoPath
                .startsWith(memoryPhotoPrefix)) {
              break;
            }
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 50)),
            );
            await tester.pumpAndSettle();
          }
        }
        final draft = tester
            .widget<CoverPreview>(find.byType(CoverPreview))
            .draft;
        expect(draft.ownerId, 'a');
        expect(draft.caption, 'keep me');
        expect(draft.photoPath.startsWith(memoryPhotoPrefix), accept);
        expect(lib.drafts, isEmpty, reason: '사진 복구는 기존 저장 자료를 자동으로 덮어쓰지 않는다');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
