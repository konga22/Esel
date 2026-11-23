import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_button.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/notification_settings_source.dart';
import '../../domain/notification_settings.dart';
import '../controllers/notification_settings_controller.dart';
import '../controllers/profile_bio_controller.dart';

class SettingsScreen extends StatefulWidget {
  final AuthController authController;
  final VoidCallback onBack;
  final Map<String, VoidCallback> deviceActions;
  final VoidCallback onLogoutComplete;
  final VoidCallback onDeleteComplete;

  /// 계정과 이 기기의 모든 호·사진·내보낸 이미지를 지운다. 없으면 계정만 지운다.
  final Future<void> Function()? deleteAccount;

  /// 마이페이지 ≡ → 프로필 편집으로 바로 열 때. 뒤로 가면 설정 메뉴가 아닌 마이페이지로 돌아간다.
  final bool openProfile;

  /// 알림 설정을 읽고 저장하는 곳(서버 모드는 GET·PUT /me/notifications). 없으면 이 화면의 메모리에만 둔다.
  final NotificationSettingsSource? notificationSettings;

  /// 서버 모드의 한 줄 소개 저장(PATCH /me/profile). 없으면(mock 모드) 소개 칸을 잠가 둔다.
  final ProfileBioController? profileBio;

  const SettingsScreen({
    super.key,
    required this.authController,
    required this.onBack,
    required this.onLogoutComplete,
    required this.onDeleteComplete,
    this.deleteAccount,
    this.deviceActions = const {},
    this.openProfile = false,
    this.notificationSettings,
    this.profileBio,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 0: S1 Menu, 1: S2 Profile, 2: S3 Notification, 3: S4 Account
  late int _activeView = widget.openProfile ? 1 : 0;
  bool _deleteAgreed = false;

  late final TextEditingController _bioController;
  late final TextEditingController _mastheadController;
  late final NotificationSettingsController _notifications;

  @override
  void initState() {
    super.initState();
    final session = widget.authController.currentSession;
    _bioController = TextEditingController(text: widget.profileBio?.bio ?? '');
    _mastheadController = TextEditingController(text: session?.masthead ?? '');
    _notifications = NotificationSettingsController(
      widget.notificationSettings ?? NotificationSettingsMemorySource(),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _mastheadController.dispose();
    _notifications.dispose();
    super.dispose();
  }

  /// 알림 설정 화면을 열 때마다 저장된 값을 다시 읽는다.
  void _openNotifications() {
    setState(() => _activeView = 2);
    _notifications.load();
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EselTokens.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EselTokens.radius20),
        ),
        title: Text('로그아웃', style: EselTypography.headlineSmall),
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
        title: Text('계정 삭제 최종 확인', style: EselTypography.headlineSmall),
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
    String title = '나의 설정';
    if (_activeView == 1) title = '프로필 편집';
    if (_activeView == 2) title = '알림 설정';
    if (_activeView == 3) title = '계정 관리';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EselTokens.space16,
        vertical: 8,
      ),
      child: Row(
        children: [
          EselPressable(
            onTap: () {
              if (_activeView != 0 && !widget.openProfile) {
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
        for (final action in widget.deviceActions.entries)
          _buildMenuTile(
            Icons.phone_android,
            action.key,
            '이 기기에 보관된 자료와 설정',
            action.value,
          ),
        _buildMenuTile(
          Icons.person_outline,
          '프로필 편집',
          '사인, 한 줄 소개',
          () => setState(() => _activeView = 1),
        ),
        _buildMenuTile(
          Icons.notifications_outlined,
          '알림 설정',
          '새 호 올리기, 반응 알림',
          _openNotifications,
        ),
        _buildMenuTile(
          Icons.shield_outlined,
          '계정 관리',
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

  Future<void> _saveBio(ProfileBioController bio) async {
    FocusScope.of(context).unfocus();
    if (await bio.save(_bioController.text) && mounted) {
      _bioController.text = bio.bio ?? '';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('소개를 저장했어요.')));
    }
  }

  Widget _buildProfileView() {
    final bio = widget.profileBio;
    InputDecoration decoration(String label, String helper, {String? error}) =>
        InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
          errorText: error,
          errorMaxLines: 3,
          filled: true,
          fillColor: EselTokens.paperWarm,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(EselTokens.radius14),
            borderSide: BorderSide.none,
          ),
        );
    Widget content() => ListView(
      padding: const EdgeInsets.all(EselTokens.space24),
      children: [
        // 사인 변경·금칙어 정책은 아직 정하지 않았다(2026-11-23 사용자 결정: 잠가 둠). 바꾸는 척하지 않는다.
        TextField(
          key: const ValueKey('profile-masthead'),
          controller: _mastheadController,
          enabled: false,
          decoration: decoration(
            '사인',
            '첫 캔버스 때 정한 이름이에요. 바꾸는 방법은 아직 정하지 않았어요.',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('profile-bio'),
          controller: _bioController,
          enabled: bio != null && !bio.isSaving,
          maxLines: 3,
          decoration: decoration(
            '한 줄 소개',
            bio == null
                ? '소개는 서버를 연결한 뒤 쓸 수 있어요.'
                // 서버가 소개를 조회 응답에 주지 않는다(서버는 바꾸지 않기로 결정). 한계를 숨기지 않는다.
                : '서버에 저장돼요. 지금은 앱을 다시 켜면 저장한 소개를 다시 불러오지 못해요.',
            error: bio?.errorMessage,
          ),
        ),
        if (bio != null) ...[
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('profile-save'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(EselSizes.touch),
              backgroundColor: EselColors.ink,
            ),
            onPressed: bio.isSaving ? null : () => _saveBio(bio),
            child: Text(bio.isSaving ? '저장하는 중…' : '소개 저장'),
          ),
        ],
      ],
    );
    return bio == null
        ? content()
        : ListenableBuilder(listenable: bio, builder: (_, _) => content());
  }

  /// S3·S3off. 서버(또는 mock 메모리)에 저장된 값만 보인다. 불러오지 못하면 기본값을 지어내지 않는다.
  Widget _buildNotificationView() => ListenableBuilder(
    listenable: _notifications,
    builder: (context, _) {
      final settings = _notifications.settings;
      if (settings == null) {
        final error = _notifications.loadError;
        if (error != null && !_notifications.isLoading) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(error, textAlign: TextAlign.center),
                TextButton(
                  key: const ValueKey('notifications-retry'),
                  onPressed: _notifications.load,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }
        return const Padding(
          key: ValueKey('notifications-loading'),
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final saving = _notifications.isSaving;
      void save(NotificationSettings next) => _notifications.update(next);
      return ListView(
        padding: const EdgeInsets.all(EselTokens.space24),
        children: [
          SwitchListTile.adaptive(
            key: const ValueKey('notify-enabled'),
            title: Text(
              '전체 알림',
              style: EselTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text('끄면 아래 알림도 모두 꺼져요', style: EselTypography.caption),
            value: settings.enabled,
            // 색을 따로 정하지 않는다. 켜진 전체 알림이 꺼진 것처럼 보이던 문제(에뮬레이터 확인).
            onChanged: saving
                ? null
                : (value) => save(settings.copyWith(enabled: value)),
          ),
          const Divider(),
          SwitchListTile.adaptive(
            key: const ValueKey('notify-new-issue'),
            title: const Text('오늘의 새 호 알림'),
            value: settings.showsNewIssue,
            onChanged: saving || !settings.enabled
                ? null
                : (value) => save(settings.copyWith(newIssue: value)),
          ),
          SwitchListTile.adaptive(
            key: const ValueKey('notify-reactions'),
            title: const Text('독자 반응 알림'),
            value: settings.showsReactions,
            onChanged: saving || !settings.enabled
                ? null
                : (value) => save(settings.copyWith(reactions: value)),
          ),
          if (_notifications.saveError case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error,
                style: EselTypography.caption.copyWith(color: EselColors.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              '설정은 저장돼요. 알림 발송은 아직 준비 중이에요.',
              style: EselTypography.caption.copyWith(color: EselColors.muted),
            ),
          ),
        ],
      );
    },
  );

  Widget _buildAccountView() {
    final session = widget.authController.currentSession;
    return ListView(
      padding: const EdgeInsets.all(EselTokens.space24),
      children: [
        Text('로그인된 계정', style: EselTypography.labelSmall),
        const SizedBox(height: 4),
        Text(session?.email ?? '', style: EselTypography.headlineSmall),
        const SizedBox(height: 32),
        EselButton(label: '로그아웃', isPrimary: false, onTap: _showLogoutDialog),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          '회원 탈퇴',
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
