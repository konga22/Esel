import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_button.dart';
import '../../../../core/ui/esel_pressable.dart';

class ShareSheet extends StatelessWidget {
  final String issueId;
  final String masthead;
  final String issueNumber;
  final bool isLocked;
  final Uri? publicUrl;

  const ShareSheet({
    super.key,
    required this.issueId,
    required this.masthead,
    required this.issueNumber,
    this.isLocked = false,
    this.publicUrl,
  });

  static Future<void> show(
    BuildContext context, {
    required String issueId,
    required String masthead,
    required String issueNumber,
    bool isLocked = false,
    Uri? publicUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareSheet(
        issueId: issueId,
        masthead: masthead,
        issueNumber: issueNumber,
        isLocked: isLocked,
        publicUrl: publicUrl,
      ),
    );
  }

  Future<void> _copyShareLink(BuildContext context) async {
    if (isLocked) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아직 올리지 않은 표지는 공유할 수 없어요.')));
      Navigator.of(context).pop();
      return;
    }

    if (publicUrl == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: publicUrl.toString()));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 복사하지 못했어요. 다시 시도해 주세요.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('공유 링크를 복사했어요'),
        backgroundColor: EselTokens.ink,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    if (isLocked || publicUrl == null) return;
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          uri: publicUrl,
          sharePositionOrigin: box == null
              ? const Rect.fromLTWH(0, 0, 1, 1)
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유창을 열지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$masthead · $issueNumber 공유',
                  style: EselTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                EselPressable(
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: EselTokens.inkSubtle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              publicUrl == null
                  ? '게시물 공유 링크는 서버 연결 후 생성할 수 있어요.'
                  : '공개된 표지는 링크를 통해 누구나 웹에서 볼 수 있습니다.',
              style: EselTypography.bodySmall.copyWith(
                color: EselTokens.inkMuted,
              ),
            ),
            const SizedBox(height: 24),
            EselButton(
              label: '링크 복사하기',
              isPrimary: true,
              icon: Icons.link_rounded,
              enabled: !isLocked && publicUrl != null,
              onTap: () => _copyShareLink(context),
            ),
            const SizedBox(height: 12),
            EselButton(
              label: '기기 공유 메뉴 열기',
              isPrimary: false,
              icon: Icons.share_outlined,
              enabled: !isLocked && publicUrl != null,
              onTap: () => _share(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
