import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/mock/demo_people.dart';

/// 에셋 정리(할 일 8): 코드가 부르는 사진은 모두 있고, 번들의 사진은 모두 쓰이며,
/// 루트 원본과 같은 이름·같은 바이트이고, 출처 표에 있다.
void main() {
  final photos = [
    for (final dir in ['assets/models', 'assets/demo'])
      ...Directory(
        dir,
      ).listSync().whereType<File>().map((f) => f.path.replaceAll('\\', '/')),
  ]..sort();

  test('코드가 부르는 에셋 파일은 모두 있다', () {
    final literal = RegExp(r"'(assets/[^']+\.(?:jpg|png))'");
    final missing = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final m in literal.allMatches(file.readAsStringSync())) {
        if (!File(m[1]!).existsSync()) missing.add('${file.path}: ${m[1]}');
      }
    }
    expect(missing, isEmpty);
  });

  test('번들의 예시 사진은 모두 예시 인물이 쓴다(쓰지 않는 사진 없음)', () {
    final used = demoPeople.map((p) => p.photoAsset).toSet();
    expect(photos.toSet(), used);
  });

  test('루트 원본과 같은 이름·같은 바이트이고, 출처 표에 있다', () {
    final readme = File('assets/README.md').readAsStringSync();
    for (final path in photos) {
      final original = File('../$path');
      expect(original.existsSync(), isTrue, reason: path);
      expect(
        File(path).readAsBytesSync(),
        original.readAsBytesSync(),
        reason: path,
      );
      expect(readme, contains('`$path`'), reason: path);
    }
    expect(readme, contains('초상권'));
  });

  test('pubspec은 쓰는 에셋 폴더만 넣는다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('assets/icons/')));
    for (final dir in ['assets/paint/', 'assets/models/', 'assets/demo/']) {
      expect(pubspec, contains('- $dir'));
    }
  });
}
