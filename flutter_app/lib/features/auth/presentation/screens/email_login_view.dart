import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_button.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../controllers/auth_controller.dart';

class EmailLoginView extends StatefulWidget {
  final AuthController authController;
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  /// 처음부터 회원가입 화면으로 연다(창간 끝의 계정 만들기).
  final bool startInSignUp;

  const EmailLoginView({
    super.key,
    required this.authController,
    required this.onBack,
    required this.onSuccess,
    this.startInSignUp = false,
  });

  @override
  State<EmailLoginView> createState() => _EmailLoginViewState();
}

class _EmailLoginViewState extends State<EmailLoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _isSignUp = widget.startInSignUp;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    widget.authController.clearError();

    bool success;
    if (_isSignUp) {
      success = await widget.authController.signupWithEmail(
        email,
        password,
        '',
      );
    } else {
      success = await widget.authController.loginWithEmail(email, password);
    }

    if (success && mounted) {
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.authController;

    return Padding(
      padding: EdgeInsets.only(
        left: EselTokens.space24,
        right: EselTokens.space24,
        top: EselTokens.space20,
        bottom: MediaQuery.of(context).viewInsets.bottom + EselTokens.space32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EselPressable(
                onTap: widget.onBack,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: EselTokens.ink,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _isSignUp ? '이메일로 가입하기' : '이메일로 로그인',
                  textAlign: TextAlign.center,
                  style: EselTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: EselTokens.space20),

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: '이메일',
              hintText: 'example@domain.com',
              filled: true,
              fillColor: EselTokens.paperWarm,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(EselTokens.radius14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: EselTokens.space12),

          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: '비밀번호 (8~128자)',
              filled: true,
              fillColor: EselTokens.paperWarm,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(EselTokens.radius14),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: EselTokens.inkSubtle,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),

          if (controller.errorMessage != null) ...[
            const SizedBox(height: EselTokens.space12),
            Text(
              controller.errorMessage!,
              style: EselTypography.caption.copyWith(
                color: EselTokens.semanticRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: EselTokens.space24),

          EselButton(
            label: controller.isLoading
                ? '처리 중...'
                : (_isSignUp ? '가입하고 시작하기' : '로그인'),
            isPrimary: true,
            onTap: controller.isLoading ? () {} : _handleSubmit,
          ),

          const SizedBox(height: EselTokens.space12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUp ? '이미 계정이 있으신가요?' : '처음이신가요?',
                style: EselTypography.bodySmall.copyWith(
                  color: EselTokens.inkMuted,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    controller.clearError();
                  });
                },
                child: Text(
                  _isSignUp ? '로그인' : '회원가입',
                  style: EselTypography.bodySmall.copyWith(
                    color: EselTokens.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
