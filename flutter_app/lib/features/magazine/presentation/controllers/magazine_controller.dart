import 'package:flutter/foundation.dart';
import '../../../../core/design/tokens.g.dart';
import '../../domain/models/magazine_models.dart';
import '../../../drafts/data/local_library.dart';

class MagazineController extends ChangeNotifier {
  LocalLibrary? localLibrary;
  String? localOwnerId;
  String? localMasthead;
  ShelfViewMode _viewMode = ShelfViewMode.covers;

  ShelfViewMode get viewMode => _viewMode;

  void toggleViewMode() {
    _viewMode = _viewMode == ShelfViewMode.covers
        ? ShelfViewMode.spines
        : ShelfViewMode.covers;
    notifyListeners();
  }

  MagazineProfile getMagazineProfile(
    String masthead, {
    required int myIssueCount,
    required bool hasPublishedToday,
  }) {
    if (localLibrary != null && masthead == localMasthead) {
      final issues = localLibrary!.issuesFor(localOwnerId ?? '');
      return MagazineProfile(
        masthead: masthead,
        bio: '',
        profilePhoto: issues.isEmpty ? '' : issues.first.photoPath,
        totalIssues: issues.length,
        issues: issues
            .map(
              (d) => IssueSummary(
                id: d.id,
                issueNumber: d.issueNumber,
                date: d.publishedOn!,
                color: d.color,
                photoAsset: d.photoPath,
                caption: d.caption,
                cover: d,
              ),
            )
            .toList(),
      );
    }
    if (masthead == 'dana' || masthead == '나') {
      final list = <IssueSummary>[];
      for (int i = myIssueCount; i >= 1; i--) {
        list.add(
          IssueSummary(
            id: 'my_issue_$i',
            issueNumber: i,
            date: '2026. 9. ${i.clamp(1, 30)}',
            color: i % 2 == 0 ? EselPaint.powder : EselPaint.sage,
            photoAsset: i % 2 == 0
                ? 'assets/demo/dana.jpg'
                : 'assets/models/m01.jpg',
            caption: '매일 한 장씩 남기는 나의 기록.',
          ),
        );
      }
      return MagazineProfile(
        masthead: 'dana',
        bio: '매일의 일상과 푸른빛을 기록하는 잡지.',
        profilePhoto: 'assets/demo/dana.jpg',
        totalIssues: myIssueCount,
        issues: list,
      );
    }

    // 타인 서가 (결호 없음 P04)
    return const MagazineProfile(
      masthead: 'seul',
      bio: '필름 카메라와 가을빛 일상.',
      profilePhoto: 'assets/models/m01.jpg',
      totalIssues: 120,
      issues: [
        IssueSummary(
          id: 'seul_120',
          issueNumber: 120,
          date: '2026. 9. 6',
          color: EselPaint.powder,
          photoAsset: 'assets/models/m01.jpg',
          caption: '바람이 불어오는 계절.',
        ),
        IssueSummary(
          id: 'seul_119',
          issueNumber: 119,
          date: '2026. 9. 5',
          color: EselPaint.sage,
          photoAsset: 'assets/models/m02.jpg',
          caption: '작은 정원의 그림자.',
        ),
        IssueSummary(
          id: 'seul_118',
          issueNumber: 118,
          date: '2026. 9. 4',
          color: EselPaint.butter,
          photoAsset: 'assets/models/m03.jpg',
          caption: '노란빛 오후 티타임.',
        ),
      ],
    );
  }
}
