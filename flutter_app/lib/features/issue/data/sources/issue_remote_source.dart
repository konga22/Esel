import '../../domain/models/public_issue.dart';
import '../../../media/domain/models/face_box.dart';
import '../../../media/domain/models/face_layout_mode.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/network/http_client.dart';
import '../../../../core/time/service_date.dart';
import '../../../reactions/domain/models/reaction_state.dart';
import '../../domain/models/server_issue.dart';

/// Swagger의 공개 응답을 공개 모델로만 투영한다. 서버가 결정한 공개 범위를 재구성하지 않는다.
ServerIssue parseServerIssue(Map<String, dynamic> value) => ServerIssue(
  id: value['id'] as String,
  publishedAt: DateTime.parse(value['publishedAt'] as String),
  masthead: value['masthead'] as String,
  caption: value['caption'] as String,
  faceMode: value['faceMode'] as String,
  mediaId: (value['media'] as Map)['id'] as String,
  number: value['issueNumber'] as int,
  date:
      ServiceDate.tryParse(value['serviceDate'] as String) ??
      (throw const FormatException('서버 날짜 형식이 올바르지 않아요.')),
  color: EselPaint.values.byName((value['color'] as Map)['id'] as String),
  liked: value['liked'] as bool,
  scrapped: value['scrapped'] as bool,
);

class IssueRemoteSource {
  final AppHttpClient http;
  IssueRemoteSource(this.http);
  Future<PublicIssue> read(PublicIssue reference) =>
      readId(reference.id, ownerId: reference.ownerId);
  Future<PublicIssue> readId(String id, {required String ownerId}) async {
    final value = await issue(id);
    return PublicIssue(
      id: value.id,
      ownerId: ownerId,
      masthead: value.masthead,
      issueNumber: value.number,
      date: value.date,
      publishedAt: value.publishedAt,
      timeLabel: '',
      color: value.color,
      photo: '',
      face: const FaceBox(.5, .3, .16),
      faceMode: switch (value.faceMode) {
        'PAINT' => FaceLayoutMode.paintStroke,
        'BEHIND_MASTHEAD' => FaceLayoutMode.behindLogo,
        'NECK_DOWN' => FaceLayoutMode.belowNeck,
        _ => FaceLayoutMode.original,
      },
      caption: value.caption,
      alt: '사진 제공 준비 중',
      liked: value.liked,
      scrapped: value.scrapped,
    );
  }

  String _path(String id) => '/issues/${Uri.encodeComponent(id)}';
  Future<ServerIssue> issue(String id) async =>
      parseServerIssue(await http.get(_path(id)));
  Future<ServerIssue> setReaction(
    String id, {
    required bool like,
    required bool enabled,
  }) async {
    final path = '${_path(id)}/${like ? 'like' : 'scrap'}';
    if (enabled) {
      await http.post(path);
    } else {
      await http.delete(path);
    }
    // 저장 후 공개 판정을 다시 확인하고 서버 상태만 표시한다.
    return issue(id);
  }

  Future<ServerPage<ReaderLine>> lines(String id, {String? cursor}) async {
    final data = await http.get(
      '${_path(id)}/lines',
      queryParams: {'cursor': ?cursor},
    );
    return ServerPage(
      (data['items'] as List)
          .map((v) => ReaderLine.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
      data['nextCursor'] as String?,
    );
  }

  Future<void> addLine(String id, String text) async {
    await http.post('${_path(id)}/lines', body: {'text': text.trim()});
  }

  Future<OwnerIssueReactions> ownerReactions(String id) async {
    final data = await http.get(
      '/me/issues/${Uri.encodeComponent(id)}/reactions',
    );
    return OwnerIssueReactions(
      likes: data['likeCount'] as int,
      scraps: data['scrapCount'] as int,
      lines: data['lineCount'] as int,
      likeMastheads: (data['likes'] as List)
          .map((v) => (v as Map)['masthead'] as String)
          .toList(),
      scrapMastheads: (data['scraps'] as List)
          .map((v) => (v as Map)['masthead'] as String)
          .toList(),
    );
  }
}
