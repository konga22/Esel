/// 실제 서버가 준 media ID를 사진 참조로 보관한다. URL·기기 파일 경로와 구분한다.
String mediaPhoto(String id) => id.isEmpty ? '' : 'media:$id';
String? mediaPhotoId(String photo) =>
    photo.startsWith('media:') && photo.length > 6 ? photo.substring(6) : null;
