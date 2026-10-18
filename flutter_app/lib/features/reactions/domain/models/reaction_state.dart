class ReaderLine {
  final String id;
  final String authorMasthead;
  final String text;
  final DateTime createdAt;

  const ReaderLine({
    required this.id,
    required this.authorMasthead,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorMasthead': authorMasthead,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
  factory ReaderLine.fromJson(Map<String, dynamic> json) => ReaderLine(
    id: json['id'] as String,
    authorMasthead: json['authorMasthead'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// P18 소유자 전용 반응 통계 (타인 비공개)
class OwnerReactionStats {
  final int? readCount;
  final int likeCount;
  final int scrapCount;
  final int readerLineCount;

  const OwnerReactionStats({
    required this.readCount,
    required this.likeCount,
    required this.scrapCount,
    required this.readerLineCount,
  });

  /// "오늘 n명이 읽었어요 · 나에게만 보여요". 아직 아무도 읽지 않았으면 그렇게 말한다.
  String get privacyNotice => readCount == null
      ? '반응은 나에게만 보여요'
      : readCount == 0
      ? '아직 읽은 독자가 없어요 · 나에게만 보여요'
      : '오늘 $readCount명이 읽었어요 · 나에게만 보여요';
}
