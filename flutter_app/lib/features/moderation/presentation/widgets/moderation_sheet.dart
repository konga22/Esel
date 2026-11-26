import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_pressable.dart';

class ModerationSheet extends StatelessWidget {
  final String authorMasthead;

  /// 신고하기(DEV-20). 시트를 닫은 뒤 부르며, 사유 입력·결과 안내는 부르는 쪽이 한다.
  /// 내 캔버스처럼 신고할 수 없으면 null이고 항목을 숨긴다.
  final VoidCallback? onReport;

  /// 차단하기(DEV-20). 시트를 닫은 뒤 부르며, 확인·결과 안내는 부르는 쪽이 한다.
  /// 내 캔버스처럼 차단할 수 없으면 null이고 항목을 숨긴다.
  final VoidCallback? onBlock;

  const ModerationSheet({
    super.key,
    required this.authorMasthead,
    this.onReport,
    this.onBlock,
  });

  static Future<void> show(
    BuildContext context, {
    required String authorMasthead,
    VoidCallback? onReport,
    VoidCallback? onBlock,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ModerationSheet(
        authorMasthead: authorMasthead,
        onReport: onReport,
        onBlock: onBlock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EselTokens.space24,
        vertical: EselTokens.space20,
      ),
      decoration: const BoxDecoration(
        color: EselTokens.paper,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EselTokens.radius24),
        ),
      ),
      child: SafeArea(
        top: false,
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
            Text(
              '$authorMasthead 님에 대한 조치',
              style: EselTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (onReport != null)
              _buildOptionTile(
                context,
                key: const Key('moderation-report'),
                icon: Icons.flag_outlined,
                title: '캔버스 신고하기',
                color: EselTokens.semanticRed,
                onTap: () {
                  Navigator.of(context).pop();
                  onReport!();
                },
              ),
            if (onBlock != null)
              _buildOptionTile(
                context,
                key: const Key('moderation-block'),
                icon: Icons.block_outlined,
                title: '$authorMasthead 님 차단하기',
                color: EselTokens.ink,
                onTap: () {
                  Navigator.of(context).pop();
                  onBlock!();
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: EselPressable(
        key: key,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EselTokens.paperWarm,
            borderRadius: BorderRadius.circular(EselTokens.radius14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: EselTypography.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
