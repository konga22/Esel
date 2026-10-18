/// P14 사인(Masthead) 규칙:
/// - 영문 소문자 a–z 만 허용
/// - 길이 2자 이상 10자 이하
/// - 공백, 숫자, 특수문자, 한글 불가
/// - 화면에서는 글자 수에 맞춰 크기를 줄인다(EselTypography.mastheadSize)
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
}
