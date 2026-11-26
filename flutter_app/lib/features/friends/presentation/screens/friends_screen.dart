import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/time/service_date.dart';
import '../../../../core/ui/esel_button.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../../core/ui/esel_image.dart';
import '../controllers/friends_controller.dart';

/// 나의 친구(F1~F3, DEV-16). 열 때마다 친구 목록과 받은 요청을 다시 읽는다.
/// 서버 모드에서는 서버가 준 사람만 보이고, 실패해도 예시로 채우지 않는다.
class FriendsScreen extends StatefulWidget {
  final FriendsController controller;
  final VoidCallback onBack;

  /// 트윈은 마이페이지에서 빠지고 친구 화면 맨 위 줄로 온다(10-18 X4-1).
  /// 트윈이 서버에 연결되기 전에는 서버 모드에서 null이라 줄을 숨긴다.
  final VoidCallback? onOpenTwin;

  /// 내 사인. 나에게는 친구 요청을 보낼 수 없다.
  final String? selfMasthead;

  const FriendsScreen({
    super.key,
    required this.controller,
    required this.onBack,
    this.onOpenTwin,
    this.selfMasthead,
  });

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  FriendsController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // 그리는 중에 다른 화면에 알림이 가지 않도록 첫 프레임 뒤에 읽는다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.load();
    });
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _accept(FriendRequestItem r) async {
    final error = await controller.acceptRequest(r);
    _toast(error ?? '${r.fromMasthead} 님과 친구가 되었어요.');
  }

  Future<void> _decline(FriendRequestItem r) async {
    final error = await controller.declineRequest(r);
    if (error != null) _toast(error);
  }

  Future<void> _showAddFriendSheet() async {
    final sent = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFriendSheet(
        controller: controller,
        selfMasthead: widget.selfMasthead,
      ),
    );
    if (sent != null) _toast('$sent 님에게 친구 요청을 보냈어요.');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: EselTokens.paper,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    final friends = controller.friends;
    final requests = controller.pendingRequests;

    if (!controller.hasLoaded) {
      if (controller.errorMessage != null) {
        return _message(
          controller.errorMessage!,
          action: TextButton(
            key: const Key('friends-retry'),
            onPressed: controller.load,
            child: const Text('다시 시도'),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: EselTokens.space24),
        children: [
          if (controller.errorMessage != null)
            _inlineError(controller.errorMessage!, controller.load),
          if (widget.onOpenTwin != null) ...[
            ListTile(
              key: const Key('friends-twin'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.people_outline, size: 26),
              title: Text('트윈', style: EselTypography.labelLarge),
              subtitle: Text(
                '친구와 같은 날 한 장씩, 두 사람의 표지',
                style: EselTypography.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onOpenTwin,
            ),
            const SizedBox(height: EselTokens.space24),
          ],
          if (requests.isNotEmpty) ...[
            Text(
              controller.hasMoreRequests
                  ? '받은 친구 요청'
                  : '받은 친구 요청 (${requests.length})',
              style: EselTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...requests.map(_buildRequestItem),
            if (controller.hasMoreRequests)
              _moreButton('friends-more-requests', controller.loadMoreRequests),
            const SizedBox(height: EselTokens.space24),
          ],
          Text(
            controller.hasMoreFriends ? '나의 친구' : '나의 친구 (${friends.length})',
            style: EselTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (friends.isEmpty)
            Padding(
              key: const Key('friends-empty'),
              padding: const EdgeInsets.symmetric(vertical: EselTokens.space16),
              child: Text(
                '아직 친구가 없어요. 오른쪽 위 버튼으로 친구의 사인을 찾아 요청을 보내 보세요.',
                style: EselTypography.bodySmall.copyWith(
                  color: EselTokens.inkMuted,
                ),
              ),
            ),
          ...friends.map(_buildFriendItem),
          if (controller.hasMoreFriends)
            _moreButton('friends-more-friends', controller.loadMoreFriends),
          if (controller.moreError != null)
            _inlineError(controller.moreError!, null),
          const SizedBox(height: EselTokens.space32),
        ],
      ),
    );
  }

  Widget _message(String text, {Widget? action}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(EselTokens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: EselTypography.bodyMedium,
          ),
          ?action,
        ],
      ),
    ),
  );

  Widget _inlineError(String text, Future<void> Function()? retry) => Padding(
    padding: const EdgeInsets.only(bottom: EselTokens.space16),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: EselTypography.bodySmall.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
        ),
        if (retry != null)
          TextButton(onPressed: retry, child: const Text('다시 시도')),
      ],
    ),
  );

  Widget _moreButton(String key, Future<void> Function() onTap) => Center(
    child: TextButton(
      key: Key(key),
      onPressed: controller.isLoadingMore ? null : onTap,
      child: Text(controller.isLoadingMore ? '불러오는 중…' : '더 보기'),
    ),
  );

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EselTokens.space16,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              EselPressable(
                onTap: widget.onBack,
                child: Semantics(
                  label: '뒤로',
                  button: true,
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
              ),
              const SizedBox(width: 8),
              Text(
                '나의 친구',
                style: EselTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          EselPressable(
            key: const Key('friends-add'),
            onTap: _showAddFriendSheet,
            child: Semantics(
              label: '친구 찾기',
              button: true,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.person_add_outlined,
                  size: 24,
                  color: EselTokens.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 사진이 없는 사람(서버 응답)은 사인 첫 글자 원으로 보인다.
  Widget _avatar(String masthead, String? photoAsset) => ClipRRect(
    borderRadius: BorderRadius.circular(EselTokens.radiusPill),
    child: photoAsset != null
        ? EselAssetImage(photoAsset, width: 44, height: 44, fit: BoxFit.cover)
        : Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            color: EselTokens.paper,
            child: Text(
              masthead.isEmpty ? '' : masthead[0],
              style: EselTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
  );

  Widget _buildRequestItem(FriendRequestItem r) {
    final busy = controller.isBusy(r.id);
    return Container(
      key: Key('friends-request-${r.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EselTokens.paperWarm,
        borderRadius: BorderRadius.circular(EselTokens.radius14),
      ),
      child: Row(
        children: [
          _avatar(r.fromMasthead, r.photoAsset),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              r.fromMasthead,
              style: EselTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            key: Key('friends-accept-${r.id}'),
            onPressed: busy ? null : () => _accept(r),
            child: const Text(
              '수락',
              style: TextStyle(
                color: EselTokens.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            key: Key('friends-decline-${r.id}'),
            onPressed: busy ? null : () => _decline(r),
            child: const Text(
              '거절',
              style: TextStyle(color: EselTokens.inkMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(FriendItem f) {
    final since = f.friendsSince;
    final subtitle =
        f.bio ?? (since == null ? null : '${ServiceDate.of(since).label}부터 친구');
    return Container(
      key: Key('friends-friend-${f.masthead}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EselTokens.paperWarm,
        borderRadius: BorderRadius.circular(EselTokens.radius14),
      ),
      child: Row(
        children: [
          _avatar(f.masthead, f.photoAsset),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.masthead,
                  style: EselTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: EselTypography.caption.copyWith(
                      color: EselTokens.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 친구 찾기 시트. 입력 컨트롤러를 이 위젯이 가지고, 시트가 화면에서 완전히 사라질 때 정리한다
/// (닫히는 애니메이션 중에도 입력 칸이 그려지기 때문이다).
/// 보내기에 성공하면 보낸 사인을 돌려주며 닫히고, 실패하면 철자를 고칠 수 있게 열어 둔다.
class _AddFriendSheet extends StatefulWidget {
  final FriendsController controller;
  final String? selfMasthead;

  const _AddFriendSheet({required this.controller, this.selfMasthead});

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final _text = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final target = normalizeFriendMasthead(_text.text);
    final message = await widget.controller.sendRequest(
      target,
      selfMasthead: widget.selfMasthead,
    );
    if (!mounted) return;
    if (message == null) {
      Navigator.of(context).pop(target);
    } else {
      setState(() {
        _sending = false;
        _error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: EselTokens.space24,
        right: EselTokens.space24,
        top: EselTokens.space20,
        bottom: MediaQuery.of(context).viewInsets.bottom + EselTokens.space32,
      ),
      decoration: const BoxDecoration(
        color: EselTokens.paper,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EselTokens.radius24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '친구 찾기',
            style: EselTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '친구의 사인(영문 닉네임)을 입력해 주세요.',
            style: EselTypography.bodySmall.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('friends-add-input'),
            controller: _text,
            autofocus: true,
            enabled: !_sending,
            autocorrect: false,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: '예: seul, yoon',
              errorText: _error,
              errorMaxLines: 3,
              filled: true,
              fillColor: EselTokens.paperWarm,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(EselTokens.radius14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          EselButton(
            key: const Key('friends-add-send'),
            label: _sending ? '보내는 중…' : '친구 요청 보내기',
            isPrimary: true,
            enabled: !_sending,
            onTap: _send,
          ),
        ],
      ),
    );
  }
}
