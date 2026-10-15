import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_button.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../../core/ui/esel_image.dart';
import '../controllers/friends_controller.dart';

class FriendsScreen extends StatelessWidget {
  final FriendsController controller;
  final VoidCallback onBack;

  const FriendsScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  void _showAddFriendSheet(BuildContext context) {
    final textCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            left: EselTokens.space24,
            right: EselTokens.space24,
            top: EselTokens.space20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + EselTokens.space32,
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
                '친구의 제호(영문 닉네임)를 입력해 주세요.',
                style: EselTypography.bodySmall.copyWith(
                  color: EselTokens.inkMuted,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: textCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '예: seul, yoon',
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
                label: '친구 요청 보내기',
                isPrimary: true,
                onTap: () {
                  final target = textCtrl.text.trim();
                  if (target.isEmpty) return;
                  final success = controller.sendRequest(target);
                  Navigator.of(ctx).pop();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$target 님에게 친구 요청을 보냈습니다.')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final friends = controller.friends;
        final requests = controller.pendingRequests;

        return Scaffold(
          backgroundColor: EselTokens.paper,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EselTokens.space24,
                    ),
                    children: [
                      if (requests.isNotEmpty) ...[
                        Text(
                          '받은 친구 요청 (${requests.length})',
                          style: EselTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...requests.map((r) => _buildRequestItem(context, r)),
                        const SizedBox(height: EselTokens.space24),
                      ],
                      Text(
                        '나의 친구 (${friends.length})',
                        style: EselTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...friends.map((f) => _buildFriendItem(f)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                onTap: onBack,
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
                '나의 친구',
                style: EselTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          EselPressable(
            onTap: () => _showAddFriendSheet(context),
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
        ],
      ),
    );
  }

  Widget _buildRequestItem(BuildContext context, FriendRequestItem r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EselTokens.paperWarm,
        borderRadius: BorderRadius.circular(EselTokens.radius14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(EselTokens.radiusPill),
            child: EselAssetImage(
              r.photoAsset,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
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
            onPressed: () {
              final ok = controller.acceptRequest(r.id);
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${r.fromMasthead} 님과 친구가 되었어요!')),
                );
              }
            },
            child: const Text(
              '수락',
              style: TextStyle(
                color: EselTokens.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => controller.declineRequest(r.id),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EselTokens.paperWarm,
        borderRadius: BorderRadius.circular(EselTokens.radius14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(EselTokens.radiusPill),
            child: EselAssetImage(
              f.photoAsset,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
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
                const SizedBox(height: 2),
                Text(
                  f.bio,
                  style: EselTypography.caption.copyWith(
                    color: EselTokens.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
