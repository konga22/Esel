import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_button.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../onboarding/domain/rules/masthead_rule.dart';

class SettingsScreen extends StatefulWidget {
  final AuthController authController;
  final VoidCallback onBack;
  final VoidCallback onLogoutComplete;
  final VoidCallback onDeleteComplete;

  /// 계정과 이 기기의 모든 호·사진·내보낸 이미지를 지운다. 없으면 계정만 지운다.
  final Future<void> Function()? deleteAccount;

  const SettingsScreen({
    super.key,
    required this.authController,
    required this.onBack,
    required this.onLogoutComplete,
    required this.onDeleteComplete,
    this.deleteAccount,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _activeView =
      0; // 0: S1 Menu, 1: S2 Profile, 2: S3 Notification, 3: S4 Account
  bool _notificationsEnabled = true;
  bool _issueNotify = true;
  bool _reactionNotify = true;
  bool _deleteAgreed = false;

  late final TextEditingController _bioController;
  late final TextEditingController _mastheadController;

  @override
  void initState() {
    super.initState();
    final session = widget.authController.currentSession;
    _bioController = TextEditingController(text: '매일의 일상과 푸른빛을 기록하는 잡지.');
    _mastheadController = TextEditingController(
      text: session?.masthead ?? 'dana',
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _mastheadController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EselTokens.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EselTokens.radius20),
        ),
        title: Text('로그아웃 (S5)', style: EselTypography.headlineSmall),
        content: Text('정말 로그아웃하시겠습니까?', style: EselTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '취소',
              style: TextStyle(color: EselTokens.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.authController.logout();
              widget.onLogoutComplete();
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(
                color: EselTokens.semanticRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EselTokens.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EselTokens.radius20),
        ),
        title: Text(
          '계정 삭제 최종 확인 (S6confirm)',
          style: EselTypography.headlineSmall,
        ),
        content: Text(
          '탈퇴 시 모든 호와 데이터가 영구히 삭제되며 복구할 수 없습니다. 계속하시겠습니까?',
          style: EselTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '취소',
              style: TextStyle(color: EselTokens.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await (widget.deleteAccount ??
                  widget.authController.deleteAccount)();
              widget.onDeleteComplete();
            },
            child: const Text(
              '영구 삭제',
              style: TextStyle(
                color: EselTokens.semanticRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EselTokens.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(child: _buildCurrentView()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = '나의 설정 (S1)';
    if (_activeView == 1) title = '프로필 편집 (S2)';
    if (_activeView == 2) title = '알림 설정 (S3)';
    if (_activeView == 3) title = '계정 관리 (S4)';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EselTokens.space16,
        vertical: 8,
      ),
      child: Row(
        children: [
          EselPressable(
            onTap: () {
              if (_activeView != 0) {
                setState(() => _activeView = 0);
              } else {
                widget.onBack();
              }
            },
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
          const SizedBox(width: 8),
          Text(
            title,
            style: EselTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_activeView) {
      case 1:
        return _buildProfileView();
      case 2:
        return _buildNotificationView();
      case 3:
        return _buildAccountView();
      default:
        return _buildMainMenuView();
    }
  }

  Widget _buildMainMenuView() {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: EselTokens.space24,
        vertical: 12,
      ),
      children: [
        _buildMenuTile(
          Icons.person_outline,
          '프로필 편집 (S2)',
          '제호, 한 줄 소개',
          () => setState(() => _activeView = 1),
        ),
        _buildMenuTile(
          Icons.notifications_outlined,
          '알림 설정 (S3)',
          '새 호 발행, 반응 알림',
          () => setState(() => _activeView = 2),
        ),
        _buildMenuTile(
          Icons.shield_outlined,
          '계정 관리 (S4)',
          '이메일, 로그아웃, 회원 탈퇴',
          () => setState(() => _activeView = 3),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EselPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EselTokens.paperWarm,
            borderRadius: BorderRadius.circular(EselTokens.radius14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: EselTokens.ink),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: EselTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: EselTypography.caption.copyWith(
                        color: EselTokens.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: EselTokens.inkSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return Padding(
      padding: const EdgeInsets.all(EselTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _mastheadController,
            decoration: InputDecoration(
              labelText: '제호 (영문 2–10자)',
              filled: true,
              fillColor: EselTokens.paperWarm,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(EselTokens.radius14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '소개 (Bio)',
              filled: true,
              fillColor: EselTokens.paperWarm,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(EselTokens.radius14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const Spacer(),
          EselButton(
            label: '프로필 저장',
            isPrimary: true,
            onTap: () {
              final masthead = _mastheadController.text.trim();
              if (!MastheadRule.isValid(masthead)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('제호는 영문 소문자 2–10자여야 합니다 (P14).'),
                  ),
                );
                return;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('프로필을 저장했어요')));
              setState(() => _activeView = 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationView() {
    return ListView(
      padding: const EdgeInsets.all(EselTokens.space24),
      children: [
        SwitchListTile.adaptive(
          title: Text(
            '전체 알림',
            style: EselTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text('모든 푸시 알림 수신', style: EselTypography.caption),
          value: _notificationsEnabled,
          activeThumbColor: EselTokens.ink,
          onChanged: (val) => setState(() => _notificationsEnabled = val),
        ),
        const Divider(),
        SwitchListTile.adaptive(
          title: const Text('오늘의 새 호 알림'),
          value: _notificationsEnabled && _issueNotify,
          onChanged: _notificationsEnabled
              ? (val) => setState(() => _issueNotify = val)
              : null,
        ),
        SwitchListTile.adaptive(
          title: const Text('독자 반응 알림'),
          value: _notificationsEnabled && _reactionNotify,
          onChanged: _notificationsEnabled
              ? (val) => setState(() => _reactionNotify = val)
              : null,
        ),
      ],
    );
  }

  Widget _buildAccountView() {
    final session = widget.authController.currentSession;
    return ListView(
      padding: const EdgeInsets.all(EselTokens.space24),
      children: [
        Text('로그인된 계정', style: EselTypography.labelSmall),
        const SizedBox(height: 4),
        Text(
          session?.email ?? 'dana@esel.app',
          style: EselTypography.headlineSmall,
        ),
        const SizedBox(height: 32),
        EselButton(
          label: '로그아웃 (S5)',
          isPrimary: false,
          onTap: _showLogoutDialog,
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          '회원 탈퇴 (S6)',
          style: EselTypography.labelMedium.copyWith(
            color: EselTokens.semanticRed,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: Text('모든 데이터가 영구 삭제됨을 확인했습니다.', style: EselTypography.caption),
          value: _deleteAgreed,
          onChanged: (v) => setState(() => _deleteAgreed = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 12),
        EselButton(
          label: '탈퇴 진행하기',
          isPrimary: false,
          onTap: _deleteAgreed ? _showDeleteConfirmDialog : () {},
        ),
      ],
    );
  }
}
