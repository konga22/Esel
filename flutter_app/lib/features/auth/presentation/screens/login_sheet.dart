import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_button.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../controllers/auth_controller.dart';
import 'email_login_view.dart';
import '../../../../core/config/app_config.dart';

class LoginSheet extends StatefulWidget {
  final AuthController authController;
  final VoidCallback onLoginSuccess;
  final VoidCallback? onCancel;

  const LoginSheet({
    super.key,
    required this.authController,
    required this.onLoginSuccess,
    this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required AuthController authController,
    required VoidCallback onLoginSuccess,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoginSheet(
        authController: authController,
        onLoginSuccess: onLoginSuccess,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  bool _showEmailView = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: EselTokens.paper,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(EselTokens.radius24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: _showEmailView
                  ? EmailLoginView(
                      authController: widget.authController,
                      onBack: () => setState(() => _showEmailView = false),
                      onSuccess: () {
                        Navigator.of(context).pop();
                        widget.onLoginSuccess();
                      },
                    )
                  : _buildSocialButtonsView(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialButtonsView(BuildContext context) {
    final controller = widget.authController;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EselTokens.space24,
        vertical: EselTokens.space20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: EselTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: EselTokens.space20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '시작하기',
                style: EselTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              EselPressable(
                onTap: () {
                  widget.onCancel?.call();
                  Navigator.of(context).pop();
                },
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.close,
                    size: 22,
                    color: EselTokens.inkSubtle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: EselTokens.space8),
          if (AppConfig.current.isMock)
            const Text('로컬 시연 · 실제 계정 인증과 동기화는 서버 연결 후 제공돼요.'),
          Text(
            '매일의 표지와 나만의 색 잡지를 발행하세요.',
            style: EselTypography.bodyMedium.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
          const SizedBox(height: EselTokens.space24),

          // 1. Apple 로그인
          EselButton(
            label: controller.isLoading ? '연결 중...' : 'Apple로 계속하기',
            isPrimary: true,
            icon: Icons.apple,
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
          const SizedBox(height: EselTokens.space12),

          // 2. Google 로그인
          EselButton(
            label: controller.isLoading ? '연결 중...' : 'Google로 계속하기',
            isPrimary: false,
            icon: Icons.g_mobiledata_rounded,
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
          const SizedBox(height: EselTokens.space12),

          // 3. 이메일 로그인 버튼 (이메일 입력 화면으로 전환)
          EselButton(
            label: '이메일로 시작하기',
            isPrimary: false,
            icon: Icons.email_outlined,
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

          const SizedBox(height: EselTokens.space20),
          Text(
            '계속 진행하면 서비스 이용약관 및 개인정보 처리방침에 동의하게 됩니다.',
            textAlign: TextAlign.center,
            style: EselTypography.caption.copyWith(color: EselTokens.inkSubtle),
          ),
          const SizedBox(height: EselTokens.space12),
        ],
      ),
    );
  }
}
