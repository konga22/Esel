import 'package:flutter/foundation.dart';

enum FeedTab { all, subs }

class FeedItem {
  final String id;
  final String masthead;
  final String date;
  final String issueNumber;
  final String colorKey;
  final String photoAsset;
  final String secondPhotoAsset;
  final String caption;
  final int sameColorCount;
  final bool isDarkCover;

  const FeedItem({
    required this.id,
    required this.masthead,
    required this.date,
    required this.issueNumber,
    required this.colorKey,
    required this.photoAsset,
    required this.secondPhotoAsset,
    required this.caption,
    required this.sameColorCount,
    this.isDarkCover = false,
  });
}

class FeedController extends ChangeNotifier {
  FeedTab _currentTab = FeedTab.all;

  FeedTab get currentTab => _currentTab;

  final List<FeedItem> _allItems = const [
    FeedItem(
      id: 'dana_249',
      masthead: 'dana',
      date: '2026. 9. 6',
      issueNumber: 'Nº 249',
      colorKey: 'powder-blue',
      photoAsset: 'assets/demo/dana.jpg',
      secondPhotoAsset: 'assets/models/m01.jpg',
      caption: '난간에 기대서, 셔츠 하나로.',
      sameColorCount: 187,
      isDarkCover: false,
    ),
    FeedItem(
      id: 'seul_120',
      masthead: 'seul',
      date: '2026. 9. 6',
      issueNumber: 'Nº 120',
      colorKey: 'sage',
      photoAsset: 'assets/models/m01.jpg',
      secondPhotoAsset: 'assets/models/m02.jpg',
      caption: '바람이 불어오는 계절.',
      sameColorCount: 142,
      isDarkCover: true,
    ),
    FeedItem(
      id: 'min_088',
      masthead: 'min',
      date: '2026. 9. 6',
      issueNumber: 'Nº 088',
      colorKey: 'butter',
      photoAsset: 'assets/models/m02.jpg',
      secondPhotoAsset: 'assets/models/m03.jpg',
      caption: '조용한 골목 끝에서.',
      sameColorCount: 95,
      isDarkCover: false,
    ),
  ];

  void switchTab(FeedTab tab) {
    _currentTab = tab;
    notifyListeners();
  }

  List<FeedItem> getItems(Set<String> subscribedMastheads) {
    if (_currentTab == FeedTab.all) {
      return _allItems;
    }
    // 구독 탭 필터링
    return _allItems
        .where((i) => subscribedMastheads.contains(i.masthead))
        .toList();
  }
}
