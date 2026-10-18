import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/features/auth/data/sources/auth_remote_source.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/media/data/media_remote_source.dart';
import 'package:esel/features/media/domain/models/face_layout_mode.dart';
import 'package:esel/features/media/presentation/controllers/media_upload_controller.dart';

// Flutter의 테스트용 HTTP 대체 대신, 명시적으로 지정한 로컬 Docker에만 접속한다.
class _LiveHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixturePath = Platform.environment['ESEL_MEDIA_FIXTURE'];
  test(
    'Docker media: rendered photos, original/thumb, account isolation and re-login',
    () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final fixture =
            jsonDecode(
                  (await File(
                    fixturePath!,
                  ).readAsString()).replaceFirst('\ufeff', ''),
                )
                as Map;
        final baseUrl = fixture['baseUrl'] as String;
        final uri = Uri.parse(baseUrl);
        if (uri.host != '127.0.0.1' || uri.scheme != 'http') {
          throw StateError('Local Docker only');
        }
        final storage = InMemorySessionStorage();
        final http = StandardHttpClient(
          config: AppConfig(apiBaseUrl: baseUrl),
          storage: storage,
        );
        final auth = AuthRemoteSource(http);
        final media = MediaRemoteSource(http);
        final upload = MediaUploadController(media);
        Future<String> login(Map account) async {
          final s = await auth.loginWithEmail(
            account['email'] as String,
            account['password'] as String,
          );
          await storage.saveTokens(
            accessToken: s.accessToken,
            refreshToken: s.refreshToken,
          );
          media.bindOwner(s.userId);
          return s.userId;
        }

        Future<void> logout() async {
          await auth.logout();
          await storage.clear();
          media.bindOwner(null);
        }

        final owner = fixture['owner'] as Map,
            reader = fixture['reader'] as Map;
        final ownerId = await login(owner);
        final asset = await rootBundle.load('assets/models/sage-01.jpg');
        final original = asset.buffer.asUint8List(
          asset.offsetInBytes,
          asset.lengthInBytes,
        );
        String? paintId;
        Uint8List? saved;
        for (final effects in [
          <FaceLayoutMode>{},
          {FaceLayoutMode.paintStroke},
          {FaceLayoutMode.belowNeck},
        ]) {
          final draft = CoverDraft(
            id: 'media-live',
            ownerId: ownerId,
            photoPath: 'asset',
            masthead: 'review',
            caption: '사진 픽셀에 넣지 않는 글자',
            faceEffects: effects,
            faceConfirmed: true,
            updatedAt: DateTime.utc(2026, 10, 19),
          );
          final id = await upload.upload(
            draft,
            readPhoto: () async => original,
          );
          final image = await media.photo(id),
              thumb = await media.photo(id, thumbnail: true);
          expect(listEquals(original, image), isFalse);
          expect(thumb, isNotEmpty);
          final codec = await ui.instantiateImageCodec(image);
          final decoded = (await codec.getNextFrame()).image;
          expect(decoded.width, 1080);
          expect(decoded.height, 1440);
          decoded.dispose();
          codec.dispose();
          if (effects.contains(FaceLayoutMode.paintStroke)) {
            paintId = id;
            saved = image;
          }
        }
        await logout();
        await login(reader);
        await expectLater(
          media.photo(paintId!),
          throwsA(isA<NotFoundFailure>()),
        );
        await logout();
        await login(owner);
        expect(listEquals(saved, await media.photo(paintId)), isTrue);
        await expectLater(
          media.photo('00000000-0000-4000-8000-000000000000'),
          throwsA(isA<NotFoundFailure>()),
        );
        await logout();
      }, _LiveHttpOverrides());
    },
    skip: fixturePath == null,
  );
}
