import '../../../auth/domain/models/auth_session.dart';
import '../../../media/domain/models/media_photo.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/network/http_client.dart';
import '../../../../core/time/service_date.dart';
import '../../../issue/data/sources/issue_remote_source.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../media/domain/models/face_box.dart';
import '../../../media/domain/models/face_layout_mode.dart';
import '../../domain/models/stand_shelf.dart';
import '../../domain/rules/same_color_rule.dart';
import 'stand_source.dart';

/// 서버 팔레트(DEV-12). 공개 권한(P01)은 서버가 먼저 거른다.
/// 추천·구독: `GET /palette/recommended|subscriptions` → 사람마다 최신 한 장(PaletteTileDto).
/// 색 방: `GET /stand?colorId=` → `{locked, closed, hiddenCount, items, nextCursor}`.
class StandRemoteSource implements StandSource {
  final AppHttpClient http;

  final AuthSession? Function()? currentSession;
  StandRemoteSource(this.http, {this.currentSession});

  @override
  Future<StandShelf> shelf({
    required SameColorViewer viewer,
    String? viewerId,
    EselPaint? color,
    PaletteTab tab = PaletteTab.recommended,
  }) async {
    if (color == null) {
      final data = await http.get(
        tab == PaletteTab.subscriptions
            ? '/palette/subscriptions'
            : '/palette/recommended',
      );
      return StandShelf(
        color: null,
        access: SameColorRoomAccess.open,
        items: [for (final tile in data['items'] as List) _tile(tile as Map)],
        hiddenCount: 0,
        // 서버가 사람마다 한 장으로 골라 준 목록. 앱이 다시 거르지 않는다.
        curated: true,
      );
    }
    final data = await http.get('/stand', queryParams: {'colorId': color.name});
    return _room(data, color, viewer.today);
  }

  @override
  Future<int> sameColorCount(ServiceDate date, EselPaint color) async {
    final data = await http.get(
      '/stand',
      queryParams: {'colorId': color.name, 'date': date.key},
    );
    final room = _room(data, color, date);
    return room.countKnown ? room.total : 0;
  }

  StandShelf _room(
    Map<String, dynamic> data,
    EselPaint color,
    ServiceDate today,
  ) {
    final date = ServiceDate.tryParse(data['serviceDate'] as String?) ?? today;
    return StandShelf(
      color: color,
      access: data['closed'] == true
          ? SameColorRoomAccess.closed
          : data['locked'] == true
          ? SameColorRoomAccess.preview
          : SameColorRoomAccess.open,
      items: [
        for (final value in data['items'] as List)
          serverIssueToPublic(
            parseServerIssue(
              Map<String, dynamic>.from(value as Map),
              date: date,
            ),
            viewer: currentSession?.call(),
          ),
      ],
      hiddenCount: data['hiddenCount'] as int? ?? 0,
      // 같은 색 인원(공개 숫자, P18). total이 없으면 잠긴 미리보기만 공개 장수 + 숨긴 수를 쓰고, 열린 방은 숫자를 숨긴다.
      count: data['total'] as int?,
      countKnown: data['total'] is int || data['locked'] == true,
    );
  }

  /// 팔레트 칸: 사진과 사인으로 그 사람 스케치북을 연다. 호수·시각·캡션은 칸에 쓰지 않는다.
  PublicIssue _tile(Map value) {
    final date =
        ServiceDate.tryParse(value['serviceDate'] as String?) ??
        (throw const FormatException('서버 날짜 형식이 올바르지 않아요.'));
    final masthead = value['masthead'] as String;
    final viewer = currentSession?.call();
    return PublicIssue(
      id: value['issueId'] as String,
      ownerId: viewer != null && viewer.masthead == masthead
          ? viewer.userId
          : masthead,
      masthead: masthead,
      issueNumber: 0,
      date: date,
      publishedAt: date.startsAt,
      timeLabel: '',
      color: EselPaint.values.byName((value['color'] as Map)['id'] as String),
      photo: mediaPhoto(((value['media'] as Map?)?['id'] as String?) ?? ''),
      face: const FaceBox(.5, .3, .16),
      faceMode: FaceLayoutMode.original,
      caption: '',
      alt: '$masthead의 착장 사진',
    );
  }
}
