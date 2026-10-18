import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/mock/demo_people.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/media/domain/models/face_box.dart';
import 'package:esel/features/media/domain/models/face_layout_mode.dart';
import 'package:esel/features/media/presentation/cover_photo.dart';
import 'package:esel/features/media/presentation/cover_preview.dart';

void main() {
  // 디자인 C6 만들기 미리보기(236×350)의 selin. 기대값은 생성기 lib.mjs 출력(px 반올림).
  final selin = demoPersonNamed('selin')!;
  final face = FaceBox(selin.faceX, selin.faceY, selin.faceWidth);
  const box = Size(236, 350);

  Rect rect(FaceLayoutMode mode) => CoverPhoto.photoRect(
    box: box,
    photoRatio: selin.ratio,
    face: face,
    mode: mode,
  );

  group('DEV-08 P15 얼굴 연출(생성기와 같은 계산)', () {
    test('물감 한 획: 폭은 얼굴 폭의 2.15배, 눈 위에 놓인다', () {
      final stroke = CoverPhoto.strokeRect(
        rect(FaceLayoutMode.paintStroke),
        face,
      );
      expect(stroke.width, closeTo(81, 1)); // faceStroke: width 81
      expect(stroke.height, closeTo(41, 1));
      expect(stroke.left, closeTo(84, 1));
      expect(stroke.top, closeTo(122, 1));
      final photo = rect(FaceLayoutMode.paintStroke);
      expect(stroke.width / (face.width * photo.width), closeTo(2.15, 1e-9));
    });

    test('사인 뒤로: 사인을 옮기지 않고 사진을 1.9배 키워 얼굴을 사인 높이로', () {
      final zoom = rect(FaceLayoutMode.behindLogo);
      expect(zoom.width, closeTo(448, 1)); // crop(…, 1.9, …)
      expect(zoom.left, closeTo(-118, 1));
      expect(zoom.top, closeTo(-223, 1));
      final faceY = zoom.top + face.y * zoom.height;
      expect(faceY, closeTo(box.height * 0.17, 1));
    });

    test('목 아래: 턱 아래부터 상자를 채운다', () {
      final neck = rect(FaceLayoutMode.belowNeck);
      expect(neck.width, closeTo(473, 1)); // neckDown
      expect(neck.left, closeTo(-131, 1));
      expect(neck.top, closeTo(-358, 1.5));
      final chin =
          neck.top + face.y * neck.height + face.width * neck.width * 0.78;
      expect(chin, closeTo(0, 1.5));
      expect(neck.bottom, greaterThanOrEqualTo(box.height));
    });

    test('목 아래: 하단 여백이 적어 4배 이상 확대되어도 얼굴이 돌아오지 않는다', () {
      const lowFace = FaceBox(.5, .8, .16);
      final neck = CoverPhoto.photoRect(
        box: box,
        photoRatio: 1,
        face: lowFace,
        mode: FaceLayoutMode.belowNeck,
      );
      expect(neck.width, greaterThan(box.width * 4));
      expect(
        neck.top + lowFace.y * neck.height + lowFace.width * neck.width * .78,
        closeTo(0, 1e-8),
      );
      expect(neck.bottom, greaterThanOrEqualTo(box.height));
    });

    test('목 아래: 턱 아래 사진이 없을 때도 얼굴을 다시 내리지 않는다', () {
      const lowFace = FaceBox(.5, .98, .16);
      final neck = CoverPhoto.photoRect(
        box: box,
        photoRatio: 1,
        face: lowFace,
        mode: FaceLayoutMode.belowNeck,
      );
      expect(
        neck.top + lowFace.y * neck.height + lowFace.width * neck.width * .78,
        closeTo(0, 1e-8),
      );
      expect(neck.bottom, lessThanOrEqualTo(0));
    });

    test('그대로: 얼굴이 위에 있으면 사인을 줄이고, 그래도 닿으면 알린다', () {
      CoverDraft draft(double faceY) => CoverDraft(
        id: 'd',
        photoPath: 'p.png',
        masthead: 'selin',
        faceY: faceY,
        updatedAt: DateTime(2026),
      );
      const cover = Size(360, 480);
      final low = CoverPreview.plainMastheadSize(draft(.6), cover);
      final high = CoverPreview.plainMastheadSize(draft(.24), cover);
      expect(high, lessThan(low));
      expect(CoverPreview.plainMastheadTouchesFace(draft(.6), cover), isFalse);
      expect(CoverPreview.plainMastheadTouchesFace(draft(.08), cover), isTrue);
      // 다른 연출에서는 줄이지 않는다(사인 뒤로는 사인이 얼굴을 덮는 연출이다).
      expect(
        CoverPreview.plainMastheadSize(
          draft(.08).copyWith(faceMode: FaceLayoutMode.behindLogo),
          cover,
        ),
        low,
      );
    });

    test('이전 저장본의 물감 폭(maskSize)은 얼굴 폭으로 읽는다', () {
      final json =
          jsonDecode(
                '{"id":"a","photoPath":"p","masthead":"ab","caption":"","color":"camel",'
                '"faceMode":"paintStroke","faceX":0.5,"faceY":0.3,"maskSize":0.43,'
                '"cropTop":0.35,"faceConfirmed":true,"whiteTitle":true,'
                '"updatedAt":"2026-10-14T00:00:00.000"}',
              )
              as Map<String, dynamic>;
      final draft = CoverDraft.fromJson(json);
      expect(draft.faceWidth, closeTo(0.2, 1e-9));
      expect(draft.toJson().containsKey('maskSize'), isFalse);
      expect(draft.toJson()['faceWidth'], closeTo(0.2, 1e-9));
    });
  });

  testWidgets('편집 중 표지를 누르면 사진에 대한 얼굴 위치가 된다', (tester) async {
    Offset? placed;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 400,
            child: CoverPreview(
              draft: CoverDraft(
                id: 'd',
                photoPath: 'missing.png',
                masthead: 'ab',
                color: EselPaint.camel,
                faceMode: FaceLayoutMode.original,
                updatedAt: DateTime(2026),
              ),
              editing: true,
              onFacePosition: (p) => placed = p,
            ),
          ),
        ),
      ),
    );
    final topLeft = tester.getTopLeft(find.byType(CoverPreview));
    await tester.tapAt(topLeft + const Offset(150, 100));
    // 3:4 사진을 3:4 상자에 그리면 비율이 그대로다.
    expect(placed!.dx, closeTo(0.5, 0.01));
    expect(placed!.dy, closeTo(0.25, 0.01));
  });

  for (final mode in FaceLayoutMode.values) {
    testWidgets('$mode 선택 상태에서도 원본에서 얼굴 위치를 정할 수 있다', (tester) async {
      Offset? placed;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 400,
              child: CoverPreview(
                draft: CoverDraft(
                  id: 'd',
                  photoPath: 'missing.png',
                  masthead: 'ab',
                  faceMode: mode,
                  updatedAt: DateTime(2026),
                ),
                editing: true,
                locatingFace: true,
                onFacePosition: (point) => placed = point,
              ),
            ),
          ),
        ),
      );
      expect(
        tester.widget<CoverPhoto>(find.byType(CoverPhoto)).mode,
        FaceLayoutMode.original,
      );
      await tester.tapAt(
        tester.getTopLeft(find.byType(CoverPreview)) + const Offset(150, 100),
      );
      expect(placed!.dx, closeTo(.5, .01));
      expect(placed!.dy, closeTo(.25, .01));
    });
  }
}
