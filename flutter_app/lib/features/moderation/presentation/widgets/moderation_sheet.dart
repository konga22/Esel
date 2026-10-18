import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_pressable.dart';

class ModerationSheet extends StatelessWidget {
  final String authorMasthead;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  const ModerationSheet({
    super.key,
    required this.authorMasthead,
    required this.onReport,
    required this.onBlock,
  });

  static Future<void> show(
    BuildContext context, {
    required String authorMasthead,
    required VoidCallback onReport,
    required VoidCallback onBlock,
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
            _buildOptionTile(
              context,
              icon: Icons.flag_outlined,
              title: '게시물 / 사용자 신고하기',
              color: EselTokens.semanticRed,
              onTap: () {
                Navigator.of(context).pop();
                onReport();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('신고가 접수되었습니다. 검토 후 조치됩니다.')),
                );
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.block_outlined,
              title: '$authorMasthead 님 차단하기',
              color: EselTokens.ink,
              onTap: () {
                Navigator.of(context).pop();
                onBlock();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$authorMasthead 님을 차단했습니다. 피드와 팔레트에서 제외됩니다.',
                    ),
                  ),
                );
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
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
