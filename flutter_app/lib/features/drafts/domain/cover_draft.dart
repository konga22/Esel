import 'package:flutter/widgets.dart';
import '../../../core/design/tokens.g.dart';
import '../../media/domain/models/face_layout_mode.dart';

/// 내 표지 초안(발행하면 issueNumber·publishedOn이 붙는다).
///
/// 얼굴 위치 [faceX]·[faceY]와 얼굴 폭 [faceWidth]는 사진에 대한 비율이다(디자인 생성기
/// PEOPLE의 fx·fy·fw와 같은 뜻). 얼굴 연출(P15)은 이 값으로 계산한다.
class CoverDraft {
  /// 얼굴 폭 기본값(예시 인물 25명의 중간쯤).
  static const double defaultFaceWidth = 0.16;

  final String id;
  final String photoPath;
  final String masthead;
  final String caption;
  final EselPaint color;
  final FaceLayoutMode faceMode;

  /// null인 이전 저장본은 faceMode 하나를 적용한다.
  final Set<FaceLayoutMode>? faceEffects;
  final double mastheadScale;
  Set<FaceLayoutMode> get effectiveFaceEffects =>
      normalizeFaceEffects(faceEffects ?? {faceMode});
  final double faceX, faceY, faceWidth;
  final bool faceConfirmed, whiteTitle;
  final DateTime updatedAt;
  final int issueNumber;
  final String ownerId;
  final String? publishedOn;
  final String? challengeId, previousIssueId;
  const CoverDraft({
    required this.id,
    required this.photoPath,
    this.masthead = '',
    this.caption = '',
    this.color = EselPaint.powder,
    this.faceMode = FaceLayoutMode.original,
    this.faceEffects,
    this.mastheadScale = 1,
    this.faceX = .5,
    this.faceY = .3,
    this.faceWidth = defaultFaceWidth,
    this.faceConfirmed = false,
    this.whiteTitle = true,
    required this.updatedAt,
    this.issueNumber = 0,
    this.ownerId = '',
    this.publishedOn,
    this.challengeId,
    this.previousIssueId,
  });
  CoverDraft copyWith({
    String? photoPath,
    String? masthead,
    String? caption,
    EselPaint? color,
    FaceLayoutMode? faceMode,
    Set<FaceLayoutMode>? faceEffects,
    double? mastheadScale,
    double? faceX,
    double? faceY,
    double? faceWidth,
    bool? faceConfirmed,
    bool? whiteTitle,
    DateTime? updatedAt,
    int? issueNumber,
    String? ownerId,
    String? publishedOn,
    String? challengeId,
    String? previousIssueId,
    bool clearChallenge = false,
  }) => CoverDraft(
    id: id,
    photoPath: photoPath ?? this.photoPath,
    masthead: masthead ?? this.masthead,
    caption: caption ?? this.caption,
    color: color ?? this.color,
    faceMode: faceEffects != null
        ? primaryFaceEffect(faceEffects)
        : faceMode ?? this.faceMode,
    faceEffects: faceEffects ?? (faceMode != null ? null : this.faceEffects),
    mastheadScale: mastheadScale ?? this.mastheadScale,
    faceX: faceX ?? this.faceX,
    faceY: faceY ?? this.faceY,
    faceWidth: faceWidth ?? this.faceWidth,
    faceConfirmed: faceConfirmed ?? this.faceConfirmed,
    whiteTitle: whiteTitle ?? this.whiteTitle,
    updatedAt: updatedAt ?? this.updatedAt,
    issueNumber: issueNumber ?? this.issueNumber,
    ownerId: ownerId ?? this.ownerId,
    publishedOn: publishedOn ?? this.publishedOn,
    challengeId: clearChallenge ? null : challengeId ?? this.challengeId,
    previousIssueId: clearChallenge
        ? null
        : previousIssueId ?? this.previousIssueId,
  );
  String? get validationError {
    if (photoPath.isEmpty) return '사진을 먼저 골라 주세요.';
    if (!RegExp(r'^[a-z]{2,10}$').hasMatch(masthead)) {
      return '제호는 영문 소문자 2~10자로 입력해 주세요.';
    }
    if (caption.characters.length > 40) return '표지 문구는 40자 이내로 입력해 주세요.';
    if (!faceConfirmed) return '얼굴 위치 또는 목 아래 자르기 영역을 확인해 주세요.';
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'photoPath': photoPath,
    'masthead': masthead,
    'caption': caption,
    'color': color.name,
    'faceMode': primaryFaceEffect(effectiveFaceEffects).name,
    'faceEffects': effectiveFaceEffects.map((mode) => mode.name).toList(),
    'mastheadScale': mastheadScale,
    'faceX': faceX,
    'faceY': faceY,
    'faceWidth': faceWidth,
    'faceConfirmed': faceConfirmed,
    'whiteTitle': whiteTitle,
    'updatedAt': updatedAt.toIso8601String(),
    'issueNumber': issueNumber,
    'ownerId': ownerId,
    'publishedOn': publishedOn,
    'challengeId': challengeId,
    'previousIssueId': previousIssueId,
  };
  factory CoverDraft.fromJson(Map<String, dynamic> json) => CoverDraft(
    id: json['id'] as String,
    photoPath: json['photoPath'] as String,
    masthead: json['masthead'] as String,
    caption: json['caption'] as String,
    color: EselPaint.values.byName(json['color'] as String),
    faceMode: FaceLayoutMode.values.byName(json['faceMode'] as String),
    faceEffects: (json['faceEffects'] as List?)
        ?.map((value) => FaceLayoutMode.values.byName(value as String))
        .toSet(),
    mastheadScale: ((json['mastheadScale'] as num?)?.toDouble() ?? 1).clamp(
      .5,
      1.4,
    ),
    faceX: (json['faceX'] as num).toDouble().clamp(0, 1),
    faceY: (json['faceY'] as num).toDouble().clamp(0, 1),
    // 이전 저장본은 물감 폭(maskSize, 표지 폭 비율)만 있어서 얼굴 폭 = 물감 폭 ÷ 2.15로 읽는다.
    faceWidth:
        ((json['faceWidth'] as num?)?.toDouble() ??
                ((json['maskSize'] as num?)?.toDouble() ??
                        defaultFaceWidth * 2.15) /
                    2.15)
            .clamp(.05, .45),
    faceConfirmed: json['faceConfirmed'] as bool,
    whiteTitle: json['whiteTitle'] as bool,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    issueNumber: json['issueNumber'] as int? ?? 0,
    ownerId: json['ownerId'] as String? ?? '',
    publishedOn: json['publishedOn'] as String?,
    challengeId: json['challengeId'] as String?,
    previousIssueId: json['previousIssueId'] as String?,
  );
}
