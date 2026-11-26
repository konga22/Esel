import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/time/service_date.dart';
import '../controllers/blocks_controller.dart';

/// 설정 > 차단한 사람(DEV-20). 열 때마다 `GET /me/blocks`를 다시 읽고, 풀기는 서버가 답한 뒤에만 뺀다.
/// 개수는 서버가 주지 않으므로 숫자 없이 목록만 보인다.
class BlockedUsersView extends StatefulWidget {
  final BlocksController controller;

  /// mock 모드 안내. 시연 피드는 차단 목록으로 거르지 않는다.
  final bool demo;

  const BlockedUsersView({
    super.key,
    required this.controller,
    this.demo = false,
  });

  @override
  State<BlockedUsersView> createState() => _BlockedUsersViewState();
}

class _BlockedUsersViewState extends State<BlockedUsersView> {
  BlocksController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.load();
    });
  }

  Future<void> _unblock(BlockedUser user) async {
    final error = await controller.unblock(user.masthead);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error ?? '${user.masthead} 님의 차단을 풀었어요.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.hasLoaded) {
          if (controller.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(EselTokens.space24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.errorMessage!,
                      textAlign: TextAlign.center,
                      style: EselTypography.bodyMedium,
                    ),
                    TextButton(
                      key: const Key('blocks-retry'),
                      onPressed: controller.load,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final items = controller.items;
        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: EselTokens.space24,
            vertical: 12,
          ),
          children: [
            Text(
              widget.demo
                  ? '시연 모드에서는 차단한 사람을 이 목록에만 담아요. 홈·팔레트는 그대로예요.'
                  : '차단한 사람의 캔버스와 한 줄은 내 홈·팔레트·스케치북에 보이지 않아요. 풀면 다시 보여요.',
              style: EselTypography.caption.copyWith(
                color: EselTokens.inkMuted,
              ),
            ),
            const SizedBox(height: EselTokens.space16),
            if (controller.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: EselTokens.space16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.errorMessage!,
                        style: EselTypography.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: controller.load,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            if (items.isEmpty)
              Padding(
                key: const Key('blocks-empty'),
                padding: const EdgeInsets.symmetric(
                  vertical: EselTokens.space16,
                ),
                child: Text('차단한 사람이 없어요.', style: EselTypography.bodyMedium),
              ),
            for (final user in items) _item(user),
            if (controller.hasMore)
              Center(
                child: TextButton(
                  key: const Key('blocks-more'),
                  onPressed: controller.isLoadingMore
                      ? null
                      : controller.loadMore,
                  child: Text(controller.isLoadingMore ? '불러오는 중…' : '더 보기'),
                ),
              ),
            if (controller.moreError != null)
              Text(controller.moreError!, style: EselTypography.bodySmall),
          ],
        );
      },
    );
  }

  Widget _item(BlockedUser user) {
    final busy = controller.isBusy(user.masthead);
    final since = user.blockedAt;
    return Container(
      key: Key('blocks-user-${user.masthead}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: EselTokens.paperWarm,
        borderRadius: BorderRadius.circular(EselTokens.radius14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.masthead,
                  style: EselTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (since != null)
                  Text(
                    '${ServiceDate.of(since).label} 차단',
                    style: EselTypography.caption.copyWith(
                      color: EselTokens.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            key: Key('blocks-unblock-${user.masthead}'),
            style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: busy ? null : () => _unblock(user),
            child: Text(
              busy ? '푸는 중…' : '풀기',
              style: const TextStyle(
                color: EselTokens.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
