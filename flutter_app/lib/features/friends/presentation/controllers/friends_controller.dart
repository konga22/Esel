import 'package:flutter/foundation.dart';

class FriendItem {
  final String id;
  final String masthead;
  final String bio;
  final String photoAsset;

  const FriendItem({
    required this.id,
    required this.masthead,
    required this.bio,
    required this.photoAsset,
  });
}

class FriendRequestItem {
  final String id;
  final String fromMasthead;
  final String photoAsset;

  const FriendRequestItem({
    required this.id,
    required this.fromMasthead,
    required this.photoAsset,
  });
}

class FriendsController extends ChangeNotifier {
  final List<FriendItem> _friends = [
    const FriendItem(
      id: 'friend_1',
      masthead: 'elin',
      bio: '라탄 의자, 세이지 셋업. 일요일 오전.',
      photoAsset: 'assets/models/sage-01.jpg',
    ),
    const FriendItem(
      id: 'friend_2',
      masthead: 'ama',
      bio: '노란 셋업에 은색 가방 하나.',
      photoAsset: 'assets/models/butter-01.jpg',
    ),
  ];

  final List<FriendRequestItem> _pendingRequests = [
    const FriendRequestItem(
      id: 'req_1',
      fromMasthead: 'kofi',
      photoAsset: 'assets/models/olive-01.jpg',
    ),
  ];

  List<FriendItem> get friends => List.unmodifiable(_friends);
  List<FriendRequestItem> get pendingRequests =>
      List.unmodifiable(_pendingRequests);

  bool acceptRequest(String requestId) {
    final idx = _pendingRequests.indexWhere((r) => r.id == requestId);
    if (idx == -1) return false;
    final req = _pendingRequests.removeAt(idx);
    _friends.add(
      FriendItem(
        id: 'friend_${req.fromMasthead}',
        masthead: req.fromMasthead,
        bio: '새로운 친구.',
        photoAsset: req.photoAsset,
      ),
    );
    notifyListeners();
    return true;
  }

  void declineRequest(String requestId) {
    _pendingRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  bool sendRequest(String targetMasthead) {
    final trimmed = targetMasthead.trim().toLowerCase();
    if (trimmed.isEmpty || trimmed == 'dana') return false;
    if (_friends.any((f) => f.masthead == trimmed)) return false;

    // 모의 친구 요청 발송
    notifyListeners();
    return true;
  }
}
