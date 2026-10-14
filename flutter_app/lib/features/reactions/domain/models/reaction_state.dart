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
}

/// P18 소유자 전용 반응 통계 (타인 비공개)
class OwnerReactionStats {
  final int readCount;
  final int likeCount;
  final int scrapCount;
  final int readerLineCount;

  const OwnerReactionStats({
    required this.readCount,
    required this.likeCount,
    required this.scrapCount,
    required this.readerLineCount,
  });

  static const String privacyNotice = '오늘 n명이 읽었어요 · 나에게만 보여요';
}
