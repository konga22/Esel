import 'package:flutter/foundation.dart';
import '../../../media/domain/models/face_layout_mode.dart';
import '../../domain/models/publish_models.dart';
import '../../domain/rules/publish_rule.dart';

class PublishingController extends ChangeNotifier {
  String _photoAsset = 'assets/demo/dana.jpg';
  String _colorId = 'powder-blue';
  String _caption = '난간에 기대서, 셔츠 하나로.';
  FaceLayoutMode _faceMode = FaceLayoutMode.paintStroke;
  MastheadColor _mastheadColor = MastheadColor.white;
  bool _isSubmitting = false;
  String? _errorMessage;

  String get photoAsset => _photoAsset;
  String get colorId => _colorId;
  String get caption => _caption;
  FaceLayoutMode get faceMode => _faceMode;
  MastheadColor get mastheadColor => _mastheadColor;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  final List<String> availablePhotos = const [
    'assets/demo/dana.jpg',
    'assets/models/m01.jpg',
    'assets/models/m02.jpg',
    'assets/models/m03.jpg',
    'assets/models/m04.jpg',
  ];

  void cyclePhoto() {
    final curIdx = availablePhotos.indexOf(_photoAsset);
    final nextIdx = (curIdx + 1) % availablePhotos.length;
    _photoAsset = availablePhotos[nextIdx];
    notifyListeners();
  }

  void setColor(String id) {
    _colorId = id;
    notifyListeners();
  }

  void setCaption(String text) {
    _caption = text;
    notifyListeners();
  }

  void setFaceMode(FaceLayoutMode mode) {
    _faceMode = mode;
    notifyListeners();
  }

  void toggleMastheadColor() {
    _mastheadColor = _mastheadColor == MastheadColor.white
        ? MastheadColor.ink
        : MastheadColor.white;
    notifyListeners();
  }

  Future<PublishResult> submitPublish({
    required bool hasPublishedToday,
    required int currentIssueCount,
  }) async {
    if (_isSubmitting) {
      return const PublishResult(
        success: false,
        newIssueCount: 0,
        message: '이미 처리 중입니다.',
      );
    }

    if (!PublishRule.canPublishToday(
      hasPublishedToday: hasPublishedToday,
      isAccountActive: true,
    )) {
      _errorMessage = '오늘은 이미 호를 발행하셨습니다. 자정 이후에 다시 발행할 수 있습니다.';
      notifyListeners();
      return PublishResult(
        success: false,
        newIssueCount: currentIssueCount,
        message: _errorMessage!,
      );
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 450));
      final nextCount = PublishRule.calculateNextIssueNumber(
        currentIssueCount: currentIssueCount,
        isPublishingSuccessful: true,
      );
      _isSubmitting = false;
      notifyListeners();
      return PublishResult(
        success: true,
        newIssueCount: nextCount,
        message: '오늘 호가 성공적으로 발행되었습니다!',
      );
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = '발행 중 오류가 발생했습니다.';
      notifyListeners();
      return PublishResult(
        success: false,
        newIssueCount: currentIssueCount,
        message: _errorMessage!,
      );
    }
  }
}
