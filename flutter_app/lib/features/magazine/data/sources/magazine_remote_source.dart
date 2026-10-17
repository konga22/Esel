import '../../../../core/errors/failures.dart';
import '../../../../core/network/http_client.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../../domain/models/magazine_models.dart';
import 'magazine_source.dart';
import '../../domain/models/server_magazine.dart';
import '../../../issue/domain/models/server_issue.dart';
import '../../../issue/data/sources/issue_remote_source.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../media/domain/models/face_box.dart';
import '../../../media/domain/models/face_layout_mode.dart';

/// 서버 공개 필터를 통과한 목록만 사용한다. 사진 URL은 아직 계약에 없어 생성하지 않는다.
class MagazineRemoteSource implements MagazineSource {
  final AppHttpClient http;

  MagazineRemoteSource(this.http);

  Future<ServerMagazine> page({
    required bool mine,
    String? masthead,
    String? cursor,
  }) async {
    if (!mine && (masthead == null || masthead.isEmpty)) {
      throw const RuleFailure('조회할 사인을 입력해 주세요.');
    }
    final data = await http.get(
      mine ? '/me/magazine' : '/magazines/${Uri.encodeComponent(masthead!)}',
      queryParams: {'cursor': ?cursor},
    );
    return ServerMagazine(
      masthead: data['masthead'] as String? ?? '',
      issueCount: data['issueCount'] as int,
      subscribed: data['isSubscribed'] as bool? ?? false,
      today: data['todayIssue'] == null
          ? null
          : parseServerIssue(
              Map<String, dynamic>.from(data['todayIssue'] as Map),
            ),
      page: ServerPage(
        (data[mine ? 'pastIssues' : 'issues'] as List)
            .map((v) => parseServerIssue(Map<String, dynamic>.from(v as Map)))
            .toList(),
        data['nextCursor'] as String?,
      ),
    );
  }

  Future<bool> subscribe(String masthead, bool enabled) async {
    final path = '/magazines/${Uri.encodeComponent(masthead)}/subscription';
    final data = enabled ? await http.post(path) : await http.delete(path);
    return data['subscribed'] as bool;
  }

  @override
  Future<MagazineProfile?> magazine(
    String ownerId, {
    required SameColorViewer viewer,
    String? viewerId,
    String? masthead,
  }) async {
    final mine = ownerId == viewerId;
    final name = masthead ?? ownerId;
    if (!mine && !RegExp(r'^[a-z]{2,10}$').hasMatch(name)) {
      throw const RuleFailure('서버 스케치북은 사용자 ID 대신 사인으로 열어 주세요.');
    }
    final result = await page(mine: mine, masthead: name);
    final issues = [
      if (result.today != null) result.today!,
      ...result.page.items,
    ];
    return MagazineProfile(
      ownerId: ownerId,
      masthead: result.masthead,
      totalIssues: result.issueCount,
      isMine: mine,
      issues: issues
          .map(
            (v) => PublicIssue(
              id: v.id,
              ownerId: ownerId,
              masthead: v.masthead,
              issueNumber: v.number,
              date: v.date,
              publishedAt: v.publishedAt,
              timeLabel: '',
              color: v.color,
              photo: '',
              face: const FaceBox(.5, .3, .16),
              faceMode: switch (v.faceMode) {
                'PAINT' => FaceLayoutMode.paintStroke,
                'BEHIND_MASTHEAD' => FaceLayoutMode.behindLogo,
                'NECK_DOWN' => FaceLayoutMode.belowNeck,
                _ => FaceLayoutMode.original,
              },
              caption: v.caption,
              alt: '사진 제공 준비 중',
            ),
          )
          .toList(),
    );
  }
}
