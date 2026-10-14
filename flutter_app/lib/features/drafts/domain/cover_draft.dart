import 'package:flutter/widgets.dart';
import '../../../core/design/tokens.g.dart';
import '../../media/domain/models/face_layout_mode.dart';

class CoverDraft {
  final String id;
  final String photoPath;
  final String masthead;
  final String caption;
  final EselPaint color;
  final FaceLayoutMode faceMode;
  final double faceX, faceY, maskSize, cropTop;
  final bool faceConfirmed, whiteTitle;
  final DateTime updatedAt;
  final int issueNumber;
  final String ownerId;
  final String? publishedOn;
  const CoverDraft({
    required this.id,
    required this.photoPath,
    this.masthead = '',
    this.caption = '',
    this.color = EselPaint.powder,
    this.faceMode = FaceLayoutMode.original,
    this.faceX = .5,
    this.faceY = .3,
    this.maskSize = .4,
    this.cropTop = .35,
    this.faceConfirmed = false,
    this.whiteTitle = true,
    required this.updatedAt,
    this.issueNumber = 0,
    this.ownerId = '',
    this.publishedOn,
  });
  CoverDraft copyWith({
    String? photoPath,
    String? masthead,
    String? caption,
    EselPaint? color,
    FaceLayoutMode? faceMode,
    double? faceX,
    double? faceY,
    double? maskSize,
    double? cropTop,
    bool? faceConfirmed,
    bool? whiteTitle,
    DateTime? updatedAt,
    int? issueNumber,
    String? ownerId,
    String? publishedOn,
  }) => CoverDraft(
    id: id,
    photoPath: photoPath ?? this.photoPath,
    masthead: masthead ?? this.masthead,
    caption: caption ?? this.caption,
    color: color ?? this.color,
    faceMode: faceMode ?? this.faceMode,
    faceX: faceX ?? this.faceX,
    faceY: faceY ?? this.faceY,
    maskSize: maskSize ?? this.maskSize,
    cropTop: cropTop ?? this.cropTop,
    faceConfirmed: faceConfirmed ?? this.faceConfirmed,
    whiteTitle: whiteTitle ?? this.whiteTitle,
    updatedAt: updatedAt ?? this.updatedAt,
    issueNumber: issueNumber ?? this.issueNumber,
    ownerId: ownerId ?? this.ownerId,
    publishedOn: publishedOn ?? this.publishedOn,
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
    'faceMode': faceMode.name,
    'faceX': faceX,
    'faceY': faceY,
    'maskSize': maskSize,
    'cropTop': cropTop,
    'faceConfirmed': faceConfirmed,
    'whiteTitle': whiteTitle,
    'updatedAt': updatedAt.toIso8601String(),
    'issueNumber': issueNumber,
    'ownerId': ownerId,
    'publishedOn': publishedOn,
  };
  factory CoverDraft.fromJson(Map<String, dynamic> json) => CoverDraft(
    id: json['id'] as String,
    photoPath: json['photoPath'] as String,
    masthead: json['masthead'] as String,
    caption: json['caption'] as String,
    color: EselPaint.values.byName(json['color'] as String),
    faceMode: FaceLayoutMode.values.byName(json['faceMode'] as String),
    faceX: (json['faceX'] as num).toDouble().clamp(0, 1),
    faceY: (json['faceY'] as num).toDouble().clamp(0, 1),
    maskSize: (json['maskSize'] as num).toDouble().clamp(.15, .9),
    cropTop: (json['cropTop'] as num).toDouble().clamp(0, .8),
    faceConfirmed: json['faceConfirmed'] as bool,
    whiteTitle: json['whiteTitle'] as bool,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    issueNumber: json['issueNumber'] as int? ?? 0,
    ownerId: json['ownerId'] as String? ?? '',
    publishedOn: json['publishedOn'] as String?,
  );
}
