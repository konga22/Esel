import 'dart:math' as math;

/// P14 제호(Masthead) 규칙:
/// - 영문 소문자 a–z 만 허용
/// - 길이 2자 이상 10자 이하
/// - 공백, 숫자, 특수문자, 한글 불가
/// - 화면 표시 시 글자 수에 따라 폰트 크기 가변
class MastheadRule {
  static final RegExp _validPattern = RegExp(r'^[a-z]{2,10}$');

  static bool isValid(String name) {
    return _validPattern.hasMatch(name);
  }

  static String sanitize(String input) {
    final filtered = input.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (filtered.length > 10) {
      return filtered.substring(0, 10);
    }
    return filtered;
  }

  static String? getValidationError(String name) {
    if (name.isEmpty) return '제호를 입력해 주세요.';
    if (name.length < 2) return '제호는 최소 2자 이상이어야 합니다.';
    if (name.length > 10) return '제호는 최대 10자까지 가능합니다.';
    if (!RegExp(r'^[a-z]+$').hasMatch(name)) {
      return '영문 소문자만 사용할 수 있습니다.';
    }
    return null;
  }

  static double calculateFontSize(String name, {double? width, double? max}) {
    if (width != null) {
      final letters = math.max(2, name.length);
      final calculated = (width * 0.9) / (letters * 0.47);
      if (max != null) return math.min(max, calculated);
      return calculated;
    }
    final len = name.length;
    if (len <= 4) return 84.0;
    if (len <= 6) return 72.0;
    if (len <= 8) return 60.0;
    return 52.0;
  }
}
