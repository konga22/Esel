import '../../../../core/design/tokens.g.dart';
import '../../../drafts/domain/cover_draft.dart';

enum ShelfViewMode { covers, spines }

class IssueSummary {
  final String id;
  final int issueNumber;
  final String date;
  final EselPaint color;
  final String photoAsset;
  final String caption;
  final CoverDraft? cover;

  const IssueSummary({
    required this.id,
    required this.issueNumber,
    required this.date,
    required this.color,
    required this.photoAsset,
    required this.caption,
    this.cover,
  });

  String get issueString => 'Nº ${issueNumber.toString().padLeft(3, '0')}';
}

class MagazineProfile {
  final String masthead;
  final String bio;
  final String profilePhoto;
  final int totalIssues;
  final List<IssueSummary> issues;

  const MagazineProfile({
    required this.masthead,
    required this.bio,
    required this.profilePhoto,
    required this.totalIssues,
    required this.issues,
  });
}
