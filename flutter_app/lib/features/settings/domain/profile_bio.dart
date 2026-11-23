/// 한 줄 소개 규칙(DEV-19). 서버 `UpdateProfileDto.bio`는 80자까지이고, 저장할 때 앞뒤 공백을 지운다.
///
/// 길이는 Dart `String.length`(UTF-16 단위)로 센다. 서버(class-validator `MaxLength`)와 같은 기준이라
/// 이모지 하나는 두 칸이다.
const bioMaxLength = 80;

String? bioError(String bio) =>
    bio.trim().length > bioMaxLength ? '소개는 $bioMaxLength자까지 쓸 수 있어요.' : null;

/// 내 스케치북에 보일 소개. 서버는 조회 응답에 소개를 주지 않아서(2026-11-23 확인, 서버는 바꾸지 않기로 결정)
/// 서버 값이 비어 있으면 이번 앱 실행에서 저장한 소개를 보인다. 앱을 다시 켜면 비어 보인다.
String shownBio({required String fromServer, String? savedThisSession}) =>
    fromServer.isNotEmpty ? fromServer : (savedThisSession ?? '');
