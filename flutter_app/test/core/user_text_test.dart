import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// 화면에 새는 내부·예시 값(할 일 9): 내부 화면·계약 ID, 서버 구현 이름, 고정 예시 날짜·숫자,
/// 예시 인물의 계정. 예시 데이터 파일(demo_people·demo_issue_catalog)과 주석은 뺀다.
void main() {
  final strings = RegExp(r"'([^'\\]|\\.)*'");
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .where(
        (f) =>
            !f.path.endsWith('demo_people.dart') &&
            !f.path.endsWith('demo_issue_catalog.dart'),
      );

  Iterable<(String, String)> literals() sync* {
    for (final file in sources) {
      for (final line in file.readAsLinesSync()) {
        final code = line.trimLeft();
        if (code.startsWith('//')) continue;
        for (final m in strings.allMatches(line)) {
          yield (file.path, m[0]!);
        }
      }
    }
  }

  test('사용자 문구에 내부 ID·서버 구현 이름·고정 예시 값이 없다', () {
    final banned = [
      RegExp(r'\((?:S|P|J|C|M|R|F|T|A)\d+[A-Za-z ]*\)'),
      RegExp(r'DEV-\d'),
      RegExp('Docker', caseSensitive: false),
      RegExp(r'Nº 249'),
      RegExp(r'2026\. 9\. 6'),
      RegExp(r'같은 색 187'),
      RegExp(r'dana@|selin@'),
      RegExp(r"^'(dana|seul|selin)'$"),
    ];
    final hits = [
      for (final (path, text) in literals())
        if (banned.any((b) => b.hasMatch(text))) '$path: $text',
    ];
    expect(hits, isEmpty);
  });

  test('앱 이름은 Esel', () {
    expect(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      contains('android:label="Esel"'),
    );
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<string>Esel</string>'));
    expect(plist, isNot(contains('<string>esel</string>')));
    expect(
      File('web/index.html').readAsStringSync(),
      contains('<title>Esel</title>'),
    );
  });
  test('DEV-25 old product words are absent from Dart string literals', () {
    final old = RegExp(r'가판대|서가|제호|창간|발행|펼침면|내 잡지|오늘 호|주간 드레스코드|월간 색 기록');
    final literal = RegExp(r"""['"]([^'"\n]*)['"]""");
    final found = <String>[];
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      for (final line in file.readAsLinesSync()) {
        if (line.trimLeft().startsWith('//')) continue;
        for (final match in literal.allMatches(line.split('//').first)) {
          if (old.hasMatch(match[1]!)) found.add('${file.path}: ${match[1]}');
        }
      }
    }
    expect(found, isEmpty);
  });
  test('server screens are removed, sources stay separate', () {
    final files = Directory(
      'lib/features',
    ).listSync(recursive: true).whereType<File>();
    expect(
      files.where((f) => RegExp(r'server_.*_screen\.dart$').hasMatch(f.path)),
      isEmpty,
    );
    expect(
      File(
        'lib/features/issue/data/sources/issue_remote_source.dart',
      ).existsSync(),
      isTrue,
    );
  });
}
