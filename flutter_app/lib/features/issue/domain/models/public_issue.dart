import '../../../garments/domain/garment.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_date.dart';
import '../../../media/domain/models/face_box.dart';
import '../../../media/domain/models/face_layout_mode.dart';
import '../../../publishing/domain/rules/publish_rule.dart';

/// 남에게 보이는 한 호(피드 지면·팔레트 표지·스케치북). 공개 응답 모델이다.
///
/// 좋아요·구독자·한 줄·스크랩 수 필드를 두지 않는다(P18). 숫자는 올린 본인에게만
/// 소유자용 응답으로 따로 온다. 같은 색 인원·호수·날짜는 공개.
class PublicIssue {
  final List<Garment> garments;
  final bool? liked, scrapped;
  final String id;
  final String ownerId;
  final String masthead;
  final int issueNumber;
  final ServiceDate date;
  final DateTime publishedAt;

  /// 지면 머리의 시각 표기(`오전 8:12`).
  final String timeLabel;
  final EselPaint color;

  /// 에셋 경로(`assets/...`) 또는 기기 보관함 사진 경로.
  final String photo;

  /// 사진 세로/가로. null이면 사진을 읽어 정한다(내가 올린 호).
  final double? photoRatio;
  final FaceBox face;
  final FaceLayoutMode faceMode;
  final Set<FaceLayoutMode>? faceEffects;
  final double mastheadScale;
  final String caption;

  /// 사진 대체 텍스트(착장 설명).
  final String alt;

  /// 사인을 먹으로 쓰는 표지(사진 위쪽이 밝음). 아니면 흰 사인 + 위쪽 그림자.
  final bool inkMasthead;

  const PublicIssue({
    this.garments = const [],
    this.liked,
    this.scrapped,
    required this.id,
    required this.ownerId,
    required this.masthead,
    required this.issueNumber,
    required this.date,
    required this.publishedAt,
    required this.timeLabel,
    required this.color,
    required this.photo,
    this.photoRatio,
    required this.face,
    required this.faceMode,
    this.faceEffects,
    this.mastheadScale = 1,
    required this.caption,
    required this.alt,
    this.inkMasthead = false,
  });

  String get issueLabel => PublishRule.formatIssueNumber(issueNumber);
}
