import 'package:flutter/foundation.dart';
import '../../../../core/design/tokens.g.dart';
import '../../domain/rules/twin_rule.dart';

class TwinController extends ChangeNotifier {
  String _partnerMasthead = 'seul';
  TwinStage _stage = TwinStage.revealed;
  EselPaint _myColor = EselPaint.powder;
  final EselPaint _partnerColor = EselPaint.sage;
  final String _myPhoto = 'assets/demo/dana.jpg';
  final String _partnerPhoto = 'assets/models/m01.jpg';
  TwinVisibility _visibility = TwinVisibility.jointPublic;
  bool _userConsented = false;
  final bool _partnerConsented = true;

  String get partnerMasthead => _partnerMasthead;
  TwinStage get stage => _stage;
  EselPaint get myColor => _myColor;
  EselPaint get partnerColor => _partnerColor;
  String get myPhoto => _myPhoto;
  String? get visiblePartnerPhoto =>
      (_stage == TwinStage.waitingForPartner) ? null : _partnerPhoto;
  TwinVisibility get visibility => _visibility;
  bool get userConsented => _userConsented;

  void startTwinWith(String partner) {
    _partnerMasthead = partner;
    _stage = TwinStage.colorSelection;
    _userConsented = false;
    notifyListeners();
  }

  void chooseColor(EselPaint color) {
    _myColor = color;
    _stage = TwinStage.readyToPost;
    notifyListeners();
  }

  void postMyCover() {
    _stage = TwinStage.revealed; // 상대도 이미 게시한 상태로 시뮬레이션
    notifyListeners();
  }

  void selectVisibility(TwinVisibility vis) {
    _visibility = vis;
    if (vis == TwinVisibility.privateRecord) {
      _stage = TwinStage.privateOnly;
    } else if (vis == TwinVisibility.soloPublic) {
      _stage = TwinStage.soloOnly;
    } else {
      _stage = TwinStage.consentWaiting;
    }
    notifyListeners();
  }

  void giveConsent() {
    _userConsented = true;
    if (TwinRule.canPublishJointIssue(
      visibility: _visibility,
      hasUserConsented: _userConsented,
      hasPartnerConsented: _partnerConsented,
    )) {
      _stage = TwinStage.published;
    }
    notifyListeners();
  }

  void reset() {
    _stage = TwinStage.revealed;
    _userConsented = false;
    notifyListeners();
  }
}
