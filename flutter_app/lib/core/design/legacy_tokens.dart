// 손으로 관리하는 이전 별칭이다. 생성 파일 tokens.g.dart에 손으로 넣어 두었던 블록을 옮겼다.
// 하네스(harness.json)에 없는 값이 섞여 있다: paperWarm, inkSubtle(Muted보다 흐려서 하네스의
// "보조 글자를 더 흐리게 하지 않음"과 어긋남), semanticGreen, space6·10·14·40, radius10~24.
// 새 코드는 tokens.g.dart의 EselColors·EselSpacing·EselRadius를 쓴다. 디자인에서 필요하다고
// 확인된 값만 harness.json으로 올리고, 쓰는 곳이 없어지면 이 파일을 지운다.
import 'package:flutter/widgets.dart';
import 'tokens.g.dart';

/// Convenience aliases for Esel design system tokens
abstract final class EselTokens {
  static const Color paper = EselColors.paper;
  static const Color paperWarm = Color(0xFFF2F2F0);
  static const Color ink = EselColors.ink;
  static const Color inkMuted = EselColors.muted;
  static const Color inkSubtle = Color(0xFFA0A29C);
  static const Color borderDefault = EselColors.hairline;
  static const Color semanticRed = EselColors.error;
  static const Color semanticGreen = Color(0xFF2E7D32);

  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;

  static const double radiusPill = EselRadius.pill;
  static const double radius24 = 24.0;
  static const double radius20 = 20.0;
  static const double radius16 = 16.0;
  static const double radius14 = 14.0;
  static const double radius12 = 12.0;
  static const double radius10 = 10.0;
}
