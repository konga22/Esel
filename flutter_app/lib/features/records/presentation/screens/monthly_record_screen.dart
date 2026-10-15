import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../controllers/records_controller.dart';

class MonthlyRecordScreen extends StatelessWidget {
  final RecordsController controller;
  final VoidCallback onBack;

  const MonthlyRecordScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  void _showRestoreDialog(BuildContext context, int day) {
    EselPaint selectedColor = EselPaint.powder;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: EselTokens.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EselTokens.radius20),
              ),
              title: Text(
                '9월 $day일의 색 복원',
                style: EselTypography.headlineSmall,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '놓친 날의 색을 채워보세요. 복원한 날은 나만 보며, 발행 호수나 피드에는 영향을 주지 않습니다.',
                    style: EselTypography.bodySmall.copyWith(
                      color: EselTokens.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('후보 색상 선택', style: EselTypography.labelSmall),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildColorOption(
                        EselPaint.powder,
                        selectedColor,
                        (c) => setDialogState(() => selectedColor = c),
                      ),
                      _buildColorOption(
                        EselPaint.sage,
                        selectedColor,
                        (c) => setDialogState(() => selectedColor = c),
                      ),
                      _buildColorOption(
                        EselPaint.butter,
                        selectedColor,
                        (c) => setDialogState(() => selectedColor = c),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    '취소',
                    style: EselTypography.bodyMedium.copyWith(
                      color: EselTokens.inkMuted,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final success = controller.restoreDay(day, selectedColor);
                    Navigator.of(ctx).pop();
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '9월 $day일의 색이 복원되었습니다. (잔여 ${controller.remainingRestores}회)',
                          ),
                          backgroundColor: EselTokens.ink,
                        ),
                      );
                    }
                  },
                  child: Text(
                    '복원하기',
                    style: EselTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: EselTokens.ink,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorOption(
    EselPaint key,
    EselPaint current,
    ValueChanged<EselPaint> onSelect,
  ) {
    final isSelected = key == current;
    final label = EselPaints.of(key).nameKo;
    return GestureDetector(
      onTap: () => onSelect(key),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? EselTokens.ink : Colors.transparent,
                width: 2,
              ),
            ),
            child: EselPaintAsset(paint: key, width: 36),
          ),
          const SizedBox(height: 4),
          Text(label, style: EselTypography.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
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
                _buildRestoreNotice(),
                const SizedBox(height: EselTokens.space20),
                Expanded(child: _buildCalendarGrid(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EselTokens.space16,
        vertical: 8,
      ),
      child: Row(
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
            '월간 색 기록 · 2026. 9',
            style: EselTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreNotice() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: EselTokens.space24),
      padding: const EdgeInsets.all(EselTokens.space14),
      decoration: BoxDecoration(
        color: EselTokens.paperWarm,
        borderRadius: BorderRadius.circular(EselTokens.radius14),
        border: Border.all(color: EselTokens.borderDefault),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_toggle_off, size: 20, color: EselTokens.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '이번 달 잔여 복원 횟수: ${controller.remainingRestores}회 (월 최대 2회)',
              style: EselTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: EselTokens.space24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: 30,
      itemBuilder: (context, idx) {
        final day = idx + 1;
        final record = controller.getRecord(day);
        final canRestore = controller.canRestore(day);

        return GestureDetector(
          onTap: () {
            if (canRestore) {
              _showRestoreDialog(context, day);
            } else {
              final reason = controller.getDenialReason(day);
              if (reason != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(reason),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: canRestore ? EselTokens.paperWarm : Colors.transparent,
              borderRadius: BorderRadius.circular(EselTokens.radius10),
              border: Border.all(
                color: canRestore
                    ? EselTokens.borderDefault
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: EselTypography.monoSmall.copyWith(
                    color: record.type == RecordType.future
                        ? EselTokens.inkSubtle
                        : EselTokens.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (record.type == RecordType.published && record.color != null)
                  EselPaintAsset(paint: record.color!, width: 20)
                else if (record.type == RecordType.restored &&
                    record.color != null)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: EselTokens.ink, width: 2),
                    ),
                  )
                else if (canRestore)
                  const Icon(Icons.add, size: 16, color: EselTokens.inkSubtle)
                else
                  const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}
