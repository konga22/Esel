import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/features/media/data/media_remote_source.dart';
import 'package:esel/features/media/presentation/remote_media_photo.dart';
import 'package:esel/features/media/presentation/cover_photo.dart';

class MissingPhotoHttp implements AppHttpClient, BinaryHttpClient {
  final requests = <String>[];
  @override
  Future<Uint8List> getBytes(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    requests.add('$path?size=${queryParams!['size']}');
    throw const NotFoundFailure('사진 없음');
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class DeferredPhotoHttp extends MissingPhotoHttp {
  final result = Completer<Uint8List>();
  @override
  Future<Uint8List> getBytes(String path, {Map<String, String>? queryParams}) =>
      result.future;
}

void main() {
  for (final failure in [
    const NotFoundFailure('사진 없음'),
    const NetworkFailure('연결 실패'),
    null,
  ]) {
    testWidgets('장식 배경은 대기 및 실패 상태 UI를 숨긴다: $failure', (tester) async {
      final http = DeferredPhotoHttp();
      final source = MediaRemoteSource(http);
      addTearDown(source.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 300,
            height: 400,
            child: RemoteMediaPhoto(
              id: 'background',
              decorative: true,
              source: source,
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      if (failure != null) {
        http.result.completeError(failure);
      } else {
        // 통신은 성공했어도 이미지로 해독할 수 없는 응답은 배경에서 숨긴다.
        http.result.complete(Uint8List.fromList([1, 2, 3]));
      }
      await tester.pumpAndSettle();
      expect(find.byType(Text), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(
        find.descendant(
          of: find.byType(RemoteMediaPhoto),
          matching: find.byType(ColoredBox),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('서버 404에는 준비 중 안내와 같은 사진 재시도가 있고 얼굴 효과를 다시 그리지 않는다', (
    tester,
  ) async {
    final http = MissingPhotoHttp();
    final source = MediaRemoteSource(http)..bindOwner('a');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 400,
            child: RemoteMediaPhoto(id: 'photo', source: source),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('사진 제공 준비 중'), findsOneWidget);
    expect(find.byType(CoverPhoto), findsNothing);
    await tester.tap(find.text('사진 다시 보기'));
    await tester.pumpAndSettle();
    expect(http.requests, [
      '/media/photo?size=original',
      '/media/photo?size=original',
    ]);
    source.bindOwner('b');
    await tester.pumpAndSettle();
    expect(http.requests, hasLength(3));
    expect(tester.takeException(), isNull);
  });
  testWidgets('작은 격자에서도 실패 안내가 넘치지 않고 thumb로 재시도한다', (tester) async {
    final http = MissingPhotoHttp();
    final source = MediaRemoteSource(http);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 80,
            height: 80,
            child: RemoteMediaPhoto(
              id: 'photo',
              thumbnail: true,
              source: source,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(http.requests, [
      '/media/photo?size=thumb',
      '/media/photo?size=thumb',
    ]);
    expect(tester.takeException(), isNull);
  });
}
