import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_glass.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../controllers/auth_controller.dart';
import 'email_login_view.dart';
import '../../../../core/config/app_config.dart';

/// 디자인 "J2 로그인": 어둡게 덮은 화면 위 Glass 시트, 위쪽 모서리 28.
/// Apple · Google · 이메일, 처음이라면 → 스케치북 만들기, 약관 안내.
class LoginSheet extends StatefulWidget {
  final AuthController authController;
  final VoidCallback onLoginSuccess;
  final VoidCallback? onCancel;

  /// "처음이라면 → 스케치북 만들기"(첫 캔버스, J3). 없으면 그 줄을 숨긴다.
  final VoidCallback? onStartJoin;

  /// 뒤에 사진이 없는 흰 화면에서 열면 true. 디자인의 "Glass 대체" 단색.
  final bool solid;

  /// 첫 캔버스 끝에서 계정을 만들 때는 제목·안내를 바꾸고, 이메일은 가입 화면으로 연다.
  final String title;
  final String lead;
  final bool emailSignUp;

  /// 시트 뒤 표지를 덮는 색. 디자인 rgba(20, 20, 18, 0.32).
  static const Color barrierColor = Color(0x52141412);

  const LoginSheet({
    super.key,
    required this.authController,
    required this.onLoginSuccess,
    this.onCancel,
    this.onStartJoin,
    this.solid = false,
    this.title = 'Esel에 들어가기',
    this.lead = '오늘의 표지를 끝까지 읽고, 구독한 잡지를 모아 봐요.',
    this.emailSignUp = false,
  });

  static Future<void> show(
    BuildContext context, {
    required AuthController authController,
    required VoidCallback onLoginSuccess,
    VoidCallback? onCancel,
    VoidCallback? onStartJoin,
    bool solid = false,
    String? title,
    String? lead,
    bool emailSignUp = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: barrierColor,
      sheetAnimationStyle: const AnimationStyle(
        duration: EselMotion.sheet,
        curve: EselMotion.drawer,
      ),
      builder: (context) => LoginSheet(
        authController: authController,
        onLoginSuccess: onLoginSuccess,
        onCancel: onCancel,
        onStartJoin: onStartJoin,
        solid: solid,
        title: title ?? 'Esel에 들어가기',
        lead: lead ?? '오늘의 표지를 끝까지 읽고, 구독한 잡지를 모아 봐요.',
        emailSignUp: emailSignUp,
      ),
    );
  }

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  static const Color _divider = Color(0xFFD3D4CE);

  bool _showEmailView = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, _) {
        return EselGlass(
          corners: const BorderRadius.vertical(
            top: Radius.circular(EselRadius.sheet),
          ),
          solid: widget.solid,
          child: SingleChildScrollView(
            child: _showEmailView
                ? SafeArea(
                    top: false,
                    child: EmailLoginView(
                      authController: widget.authController,
                      startInSignUp: widget.emailSignUp,
                      onBack: () => setState(() => _showEmailView = false),
                      onSuccess: () {
                        Navigator.of(context).pop();
                        widget.onLoginSuccess();
                      },
                    ),
                  )
                : _buildSocialButtonsView(context),
          ),
        );
      },
    );
  }

  Widget _buildSocialButtonsView(BuildContext context) {
    final controller = widget.authController;
    // 디자인: 안쪽 10 20 40, 줄 사이 10. 홈 인디케이터가 더 높으면 그 위까지.
    final bottom = math.max(40.0, MediaQuery.paddingOf(context).bottom);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x40292A27),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: EselTypography.heading(fontSize: 30),
                ),
              ),
              // 닫기 48×48은 오른쪽 여백 안으로 12 들어간다(디자인 margin-right -12).
              Transform.translate(
                offset: const Offset(12, 0),
                child: EselPressable(
                  semanticsLabel: '닫기',
                  onTap: () {
                    widget.onCancel?.call();
                    Navigator.of(context).pop();
                  },
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.close, size: 22, color: EselColors.ink),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.lead,
            style: EselTypography.body(
              fontSize: 14,
              color: EselColors.sub,
            ).copyWith(height: 1.55),
          ),
          if (AppConfig.current.isMock) ...[
            const SizedBox(height: 4),
            Text(
              '로컬 시연 · 실제 계정 인증과 동기화는 서버 연결 후 제공돼요.',
              style: EselTypography.caption,
            ),
          ],
          const SizedBox(height: 16),

          // 1·2. Apple·Google 로그인: 서버 계약에 아직 없어 시연(mock) 모드에서만 보인다.
          if (AppConfig.current.isMock) ...[
            _LoginOption(
              label: controller.isLoading ? '연결 중...' : 'Apple로 계속하기',
              icon: Icons.apple,
              dark: true,
              onTap: controller.isLoading
                  ? () {}
                  : () async {
                      final success = await controller.loginWithApple();
                      if (success && context.mounted) {
                        Navigator.of(context).pop();
                        widget.onLoginSuccess();
                      }
                    },
            ),
            const SizedBox(height: 10),

            _LoginOption(
              label: controller.isLoading ? '연결 중...' : 'Google로 계속하기',
              onTap: controller.isLoading
                  ? () {}
                  : () async {
                      final success = await controller.loginWithGoogle();
                      if (success && context.mounted) {
                        Navigator.of(context).pop();
                        widget.onLoginSuccess();
                      }
                    },
            ),
            const SizedBox(height: 10),
          ],
          // 3. 이메일 로그인 버튼 (이메일 입력 화면으로 전환)
          _LoginOption(
            label: '이메일로 계속하기',
            icon: Icons.mail_outline,
            onTap: () {
              controller.clearError();
              setState(() {
                _showEmailView = true;
              });
            },
          ),

          if (controller.errorMessage != null) ...[
            const SizedBox(height: EselTokens.space12),
            Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: EselTypography.caption.copyWith(
                color: EselTokens.semanticRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // 4. 처음이라면 → 스케치북 만들기
          if (widget.onStartJoin != null) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Divider(height: 1, thickness: 1, color: _divider),
                ),
                const SizedBox(width: 12),
                Text(
                  '처음이라면',
                  style: EselTypography.body(
                    fontSize: 13,
                    color: EselColors.muted,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Divider(height: 1, thickness: 1, color: _divider),
                ),
              ],
            ),
            const SizedBox(height: 12),
            EselPressable(
              semanticsLabel: '스케치북 만들기',
              onTap: () {
                Navigator.of(context).pop();
                widget.onStartJoin!();
              },
              child: SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('스케치북 만들기', style: EselTypography.label(fontSize: 16)),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: EselColors.ink,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
          Text(
            '계속하면 이용약관과 개인정보 처리방침에 동의하게 돼요.',
            textAlign: TextAlign.center,
            style: EselTypography.caption.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// 디자인 "소셜 로그인": 높이 54. Apple은 Ink 채움, Google·이메일은 흰 바탕 + #D8D9D3 1px.
class _LoginOption extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool dark;
  final VoidCallback onTap;

  const _LoginOption({
    required this.label,
    required this.onTap,
    this.icon,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? EselColors.paper : EselColors.ink;
    return EselPressable(
      semanticsLabel: label,
      onTap: onTap,
      child: Container(
        height: EselSizes.button,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark ? EselColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(EselSizes.button / 2),
          border: dark ? null : Border.all(color: EselColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 10),
            ],
            Text(label, style: EselTypography.label(fontSize: 16, color: fg)),
          ],
        ),
      ),
    );
  }
}
