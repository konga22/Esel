import 'package:flutter/foundation.dart';
import '../../domain/rules/same_color_rule.dart';

class StandItem {
  final String id;
  final String masthead;
  final String photoAsset;
  final String colorKey;
  final String issueNumber;
  final String caption;

  const StandItem({
    required this.id,
    required this.masthead,
    required this.photoAsset,
    required this.colorKey,
    required this.issueNumber,
    required this.caption,
  });
}

class StandController extends ChangeNotifier {
  String _selectedColorKey = 'powder-blue';

  String get selectedColorKey => _selectedColorKey;

  final Map<String, List<StandItem>> _colorItemsMap = {
    'powder-blue': [
      const StandItem(
        id: 'dana_249',
        masthead: 'dana',
        photoAsset: 'assets/demo/dana.jpg',
        colorKey: 'powder-blue',
        issueNumber: 'Nº 249',
        caption: '난간에 기대서, 셔츠 하나로.',
      ),
      const StandItem(
        id: 'm01_item',
        masthead: 'seul',
        photoAsset: 'assets/models/m01.jpg',
        colorKey: 'powder-blue',
        issueNumber: 'Nº 120',
        caption: '바람이 불어오는 계절.',
      ),
      const StandItem(
        id: 'm02_item',
        masthead: 'min',
        photoAsset: 'assets/models/m02.jpg',
        colorKey: 'powder-blue',
        issueNumber: 'Nº 088',
        caption: '조용한 골목 끝에서.',
      ),
      const StandItem(
        id: 'm03_item',
        masthead: 'yoon',
        photoAsset: 'assets/models/m03.jpg',
        colorKey: 'powder-blue',
        issueNumber: 'Nº 045',
        caption: '빛이 머무는 자리.',
      ),
      const StandItem(
        id: 'm04_item',
        masthead: 'chae',
        photoAsset: 'assets/models/m04.jpg',
        colorKey: 'powder-blue',
        issueNumber: 'Nº 012',
        caption: '파란 오후의 공기.',
      ),
    ],
    'sage': [
      const StandItem(
        id: 'm05_item',
        masthead: 'arin',
        photoAsset: 'assets/models/m05.jpg',
        colorKey: 'sage',
        issueNumber: 'Nº 099',
        caption: '풀잎의 온기.',
      ),
      const StandItem(
        id: 'm06_item',
        masthead: 'haru',
        photoAsset: 'assets/models/m06.jpg',
        colorKey: 'sage',
        issueNumber: 'Nº 054',
        caption: '초록 사이로.',
      ),
    ],
    'butter': [
      const StandItem(
        id: 'm07_item',
        masthead: 'noah',
        photoAsset: 'assets/models/m07.jpg',
        colorKey: 'butter',
        issueNumber: 'Nº 210',
        caption: '오후 햇살 한 스푼.',
      ),
    ],
  };

  void selectColor(String colorKey) {
    _selectedColorKey = colorKey;
    notifyListeners();
  }

  SameColorPreviewResult getRoomEvaluation({
    required String mySelectedColorKey,
    required bool hasPublishedToday,
  }) {
    final items = _colorItemsMap[_selectedColorKey] ?? [];
    return SameColorRule.evaluateRoom(
      roomColorKey: _selectedColorKey,
      mySelectedColorKey: mySelectedColorKey,
      hasPublishedToday: hasPublishedToday,
      allCoverIdsInRoom: items.map((e) => e.id).toList(),
    );
  }

  List<StandItem> getVisibleItems({
    required String mySelectedColorKey,
    required bool hasPublishedToday,
  }) {
    final eval = getRoomEvaluation(
      mySelectedColorKey: mySelectedColorKey,
      hasPublishedToday: hasPublishedToday,
    );
    final allItems = _colorItemsMap[_selectedColorKey] ?? [];
    return allItems
        .where((item) => eval.visibleCoverIds.contains(item.id))
        .toList();
  }
}
