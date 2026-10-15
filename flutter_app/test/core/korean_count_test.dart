import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/text/korean_count.dart';

void main() {
  test('단위 명사 앞 고유어 수', () {
    expect(koreanCount(1), '한');
    expect(koreanCount(4), '네');
    expect(koreanCount(12), '열두');
    expect(koreanCount(20), '스무');
    expect(koreanCount(24), '스물네');
    expect(koreanCount(99), '아흔아홉');
    expect(koreanCount(120), '120');
  });
}
