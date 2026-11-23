import '../../../core/network/http_client.dart';

/// 한 줄 소개를 저장하는 곳. 서버 모드에만 있다(mock 모드는 소개 칸을 잠가 둔다).
abstract class ProfileBioSource {
  /// 저장한 뒤 서버가 확정한 소개(앞뒤 공백 제거)를 돌려준다.
  Future<String> updateBio(String bio);
}

/// `PATCH /me/profile`. 사인 변경은 정책이 정해지지 않아(2026-11-23 사용자 결정) 소개만 보낸다.
class ProfileRemoteSource implements ProfileBioSource {
  final AppHttpClient http;
  ProfileRemoteSource(this.http);

  @override
  Future<String> updateBio(String bio) async {
    final data = await http.patch('/me/profile', body: {'bio': bio.trim()});
    return data['bio'] as String;
  }
}
