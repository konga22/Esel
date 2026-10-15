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
  bool _userPosted = true;
  bool _partnerPosted = true;

  /// 상대 표지는 둘 다 게시한 뒤에만 보인다(P08).
  String? get visiblePartnerPhoto =>
      TwinRule.canRevealPartnerPhoto(
        hasUserPosted: _userPosted,
        hasPartnerPosted: _partnerPosted,
      )
      ? _partnerPhoto
      : null;
  TwinVisibility get visibility => _visibility;
  bool get userConsented => _userConsented;

  void startTwinWith(String partner) {
    _partnerMasthead = partner;
    _stage = TwinStage.colorSelection;
    _userConsented = false;
    _userPosted = false;
    _partnerPosted = false;
    notifyListeners();
  }

  void chooseColor(EselPaint color) {
    _myColor = color;
    _stage = TwinStage.readyToPost;
    notifyListeners();
  }

  void postMyCover() {
    _userPosted = true;
    _stage = _partnerPosted ? TwinStage.revealed : TwinStage.waitingForPartner;
    notifyListeners();
  }

  /// 상대가 게시했다(서버 알림 자리. 시연에서는 화면이 부른다).
  void partnerPosted() {
    _partnerPosted = true;
    if (_userPosted) _stage = TwinStage.revealed;
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
    _userPosted = true;
    _partnerPosted = true;
    _userConsented = false;
    notifyListeners();
  }
}
