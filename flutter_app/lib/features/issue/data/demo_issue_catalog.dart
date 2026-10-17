import '../../../core/design/tokens.g.dart';
import '../../../core/mock/demo_people.dart';
import '../../../core/time/service_date.dart';
import '../../drafts/domain/cover_draft.dart';
import '../../media/domain/models/face_box.dart';
import '../../media/domain/models/face_layout_mode.dart';
import '../domain/models/public_issue.dart';

/// 시연(mock) 데이터를 날짜에 맞춰 만든다. 서버가 생기면 이 파일은 쓰지 않는다.
///
/// - 예시 인물은 모두 매일 한 호씩 발행한다고 둔다(결호 없음, P04).
/// - 호수는 디자인 시안 날짜(2026-09-06)에 dana가 Nº 038이 되도록 셌다.
/// - 사진은 사람마다 한 장이라, 지난 호는 얼굴 연출을 바꿔 가며 보여 준다.
abstract final class DemoIssueCatalog {
  static const ServiceDate anchor = ServiceDate(2026, 9, 6);

  /// 피드 안쪽 지면 순서(디자인 C7): 표지 dana, 그다음 ama·lise·kofi·rio·omar·riva.
  static const List<String> feedOrder = [
    'dana',
    'ama',
    'lise',
    'kofi',
    'rio',
    'omar',
    'riva',
  ];

  /// 사람마다 고른 얼굴 연출(디자인 C7·C8). 나머지는 그대로.
  static const Map<String, FaceLayoutMode> _faceModes = {
    'lise': FaceLayoutMode.paintStroke,
    'omar': FaceLayoutMode.belowNeck,
    'leo': FaceLayoutMode.belowNeck,
    'noor': FaceLayoutMode.behindLogo,
  };

  /// 생성기 OLDER_COLORS. 엿새보다 오래된 호의 색.
  static const List<EselPaint> _olderColors = [
    EselPaint.coral, EselPaint.sage, EselPaint.butter, EselPaint.cobalt, //
    EselPaint.cream, EselPaint.powder, EselPaint.lilac, EselPaint.camel,
    EselPaint.olive, EselPaint.powder, EselPaint.terracotta,
    EselPaint.charcoal, EselPaint.sage, EselPaint.powder, EselPaint.burgundy,
    EselPaint.butter, EselPaint.powder, EselPaint.coral, EselPaint.cream,
    EselPaint.powder,
  ];

  /// 디자인에서 먹 제호를 쓴 표지(위쪽이 밝은 사진).
  static const Set<String> _inkMasthead = {'dana', 'kofi', 'maya', 'leo'};

  static const List<FaceLayoutMode> _shelfModes = [
    FaceLayoutMode.original,
    FaceLayoutMode.paintStroke,
    FaceLayoutMode.behindLogo,
    FaceLayoutMode.belowNeck,
  ];

  static String ownerIdOf(String name) => 'demo_$name';

  static DemoPerson? personOf(String ownerId) => ownerId.startsWith('demo_')
      ? demoPersonNamed(ownerId.substring(5))
      : null;

  /// 시안 날짜의 호수. dana는 38, 다른 사람은 이름으로 정한 12~91.
  static int _anchorNumber(DemoPerson person) => person.name == 'dana'
      ? 38
      : 12 + person.name.codeUnits.fold(0, (a, b) => a + b) % 80;

  static int issueNumberOn(DemoPerson person, ServiceDate date) {
    final days = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(anchor.year, anchor.month, anchor.day)).inDays;
    return _anchorNumber(person) + days;
  }

  /// 그 사람이 그날 낸 호. 창간 전 날짜면 null.
  static PublicIssue? issueOf(
    DemoPerson person,
    ServiceDate date, {
    required ServiceDate today,
  }) {
    final number = issueNumberOn(person, date);
    if (number < 1) return null;
    final daysAgo = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(date.year, date.month, date.day)).inDays;
    final color = daysAgo < 6
        ? person.color
        : _olderColors[(daysAgo - 6) % _olderColors.length];
    final faceMode = daysAgo == 0
        ? (_faceModes[person.name] ?? FaceLayoutMode.original)
        : _shelfModes[number % _shelfModes.length];
    return PublicIssue(
      id: '${person.name}-${date.key}',
      ownerId: ownerIdOf(person.name),
      masthead: person.name,
      issueNumber: number,
      date: date,
      publishedAt: date.startsAt.add(Duration(minutes: person.minuteOfDay)),
      timeLabel: person.time,
      color: color,
      photo: person.photoAsset,
      photoRatio: person.ratio,
      face: FaceBox(person.faceX, person.faceY, person.faceWidth),
      faceMode: faceMode,
      caption: person.caption,
      alt: person.alt,
      inkMasthead: _inkMasthead.contains(person.name),
    );
  }

  /// 그날 예시 인물이 낸 호 전부.
  static List<PublicIssue> issuesOn(ServiceDate date, {ServiceDate? today}) => [
    for (final person in demoPeople)
      ?issueOf(person, date, today: today ?? date),
  ];

  /// 내가 이 기기에서 발행한 호를 공개 모양으로. 얼굴 위치·폭은 표지에서 정한 값이고,
  /// 사진 비율은 그릴 때 사진을 읽어 정한다.
  static PublicIssue fromLocal(CoverDraft issue) => PublicIssue(
    id: issue.id,
    ownerId: issue.ownerId,
    masthead: issue.masthead,
    issueNumber: issue.issueNumber,
    date: ServiceDate.tryParse(issue.publishedOn)!,
    publishedAt: issue.updatedAt,
    timeLabel: seoulTimeLabel(issue.updatedAt),
    color: issue.color,
    photo: issue.photoPath,
    face: FaceBox(issue.faceX, issue.faceY, issue.faceWidth),
    faceMode: issue.faceMode,
    faceEffects: issue.effectiveFaceEffects,
    mastheadScale: issue.mastheadScale,
    caption: issue.caption,
    alt: '${issue.masthead}의 오늘 착장',
    inkMasthead: !issue.whiteTitle,
  );
}
