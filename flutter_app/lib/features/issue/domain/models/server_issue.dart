import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_date.dart';

/// 실제 공개 DTO에 존재하는 정보만 보관한다. 사용자 ID·반응 숫자·사진 URL을 지어내지 않는다.
class ServerIssue {
  final String id, masthead, caption, faceMode, mediaId;
  final int number;
  final ServiceDate date;
  final DateTime publishedAt;
  final EselPaint color;
  final bool liked, scrapped;
  const ServerIssue({
    required this.id,
    required this.masthead,
    required this.caption,
    required this.faceMode,
    required this.mediaId,
    required this.number,
    required this.date,
    required this.publishedAt,
    required this.color,
    required this.liked,
    required this.scrapped,
  });
}

class ServerPage<T> {
  final List<T> items;
  final String? nextCursor;
  const ServerPage(this.items, this.nextCursor);
}

class OwnerIssueReactions {
  final int likes, scraps, lines;
  final List<String> likeMastheads, scrapMastheads;
  const OwnerIssueReactions({
    required this.likes,
    required this.scraps,
    required this.lines,
    required this.likeMastheads,
    required this.scrapMastheads,
  });
}
