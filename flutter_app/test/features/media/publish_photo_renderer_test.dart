import 'package:esel/core/network/http_client.dart';
import 'package:esel/features/media/data/media_remote_source.dart';
import 'package:esel/features/media/presentation/controllers/media_upload_controller.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/media/domain/models/face_layout_mode.dart';
import 'package:esel/features/media/presentation/publish_photo_renderer.dart';

class EmptyHttp implements AppHttpClient {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class RecordingMedia extends MediaRemoteSource {
  Uint8List? sent;
  RecordingMedia() : super(EmptyHttp());
  @override
  Future<String> upload(
    Uint8List bytes, {
    String mimeType = 'image/png',
  }) async {
    sent = bytes;
    return 'ready-id';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CoverDraft draft(Set<FaceLayoutMode> effects) => CoverDraft(
    id: 'draft',
    photoPath: 'private-local-source',
    masthead: 'style',
    caption: '업로드 픽셀에 포함하면 안 되는 문구',
    faceEffects: effects,
    faceConfirmed: true,
    updatedAt: DateTime(2026, 10, 19),
  );
  Future<Uint8List> source() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xffeeeeee), ui.BlendMode.src);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 120, 60),
      ui.Paint()..color = const ui.Color(0xffff0000),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(120, 160);
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  test('사인 뒤로는 디코딩 전 차단하며 물감 조합이나 이전 단일 저장본도 우회하지 못한다', () async {
    for (final value in [
      draft({FaceLayoutMode.behindLogo}),
      draft({FaceLayoutMode.behindLogo, FaceLayoutMode.paintStroke}),
      draft({}).copyWith(faceMode: FaceLayoutMode.behindLogo),
    ]) {
      await expectLater(
        PublishPhotoRenderer.render(value, Uint8List(0)),
        throwsA(
          isA<RuleFailure>().having(
            (e) => e.code,
            '보류 이유 식별 코드',
            'SIGNATURE_UPLOAD_PENDING',
          ),
        ),
      );
      // 실패 후에도 기기 미리보기·저장 초안의 선택값을 임의로 바꾸지 않는다.
      expect(value.effectiveFaceEffects, contains(FaceLayoutMode.behindLogo));
    }
  });

  test('사인·캡션·글자 크기는 서버 PNG 픽셀에 들어가지 않는다', () async {
    final bytes = await source();
    final plain = draft({});
    final a = await PublishPhotoRenderer.render(plain, bytes, width: 120);
    final b = await PublishPhotoRenderer.render(
      plain.copyWith(
        masthead: 'different',
        caption: '다른 문구',
        mastheadScale: 1.4,
      ),
      bytes,
      width: 120,
    );
    expect(a, orderedEquals(b));
    final codec = await ui.instantiateImageCodec(a);
    final image = (await codec.getNextFrame()).image;
    expect(image.width, 120);
    expect(image.height, 160);
    image.dispose();
    codec.dispose();
  });

  test('물감은 사진 픽셀에 반영되고 목 아래는 얼굴 영역을 잘라낸다', () async {
    final bytes = await source();
    final plain = await PublishPhotoRenderer.render(
      draft({}),
      bytes,
      width: 120,
    );
    final paint = await PublishPhotoRenderer.render(
      draft({FaceLayoutMode.paintStroke}),
      bytes,
      width: 120,
    );
    final neck = await PublishPhotoRenderer.render(
      draft({FaceLayoutMode.belowNeck}),
      bytes,
      width: 120,
    );
    expect(paint, isNot(orderedEquals(plain)));
    final codec = await ui.instantiateImageCodec(neck);
    final image = (await codec.getNextFrame()).image;
    final rgba = await image.toByteData();
    // 상단 빨간 얼굴 영역이 아닌 아래 회색 옷 영역으로 시작한다.
    expect(rgba!.getUint8(0), 238);
    expect(rgba.getUint8(1), 238);
    image.dispose();
    codec.dispose();
  });
  test('실제 업로드 경계에서 사인 뒤로는 파일도 읽지 않고 원본 대신 렌더링 결과만 전달한다', () async {
    final media = RecordingMedia()..bindOwner('owner');
    final controller = MediaUploadController(media);
    var read = false;
    await expectLater(
      controller.upload(
        draft({FaceLayoutMode.behindLogo}).copyWith(ownerId: 'owner'),
        readPhoto: () async {
          read = true;
          return source();
        },
      ),
      throwsA(
        isA<RuleFailure>().having(
          (e) => e.code,
          'code',
          'SIGNATURE_UPLOAD_PENDING',
        ),
      ),
    );
    expect(read, isFalse);
    expect(media.sent, isNull);
    final original = await source();
    expect(
      await controller.upload(
        draft({FaceLayoutMode.paintStroke}).copyWith(ownerId: 'owner'),
        readPhoto: () async => original,
      ),
      'ready-id',
    );
    expect(media.sent, isNot(orderedEquals(original)));
    final codec = await ui.instantiateImageCodec(media.sent!);
    final image = (await codec.getNextFrame()).image;
    expect(image.width, 1080);
    expect(image.height, 1440);
    image.dispose();
    codec.dispose();
  });
  test('사진을 읽는 중 계정이 바뀌면 다른 계정으로 업로드하지 않는다', () async {
    final media = RecordingMedia()..bindOwner('owner');
    final controller = MediaUploadController(media);
    await expectLater(
      controller.upload(
        draft({}).copyWith(ownerId: 'owner'),
        readPhoto: () async {
          media.bindOwner('other');
          return source();
        },
      ),
      throwsA(isA<AuthFailure>()),
    );
    expect(media.sent, isNull);
  });
}
