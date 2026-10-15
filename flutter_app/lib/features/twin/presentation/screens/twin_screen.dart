import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_button.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../../core/ui/esel_image.dart';
import '../../domain/rules/twin_rule.dart';
import '../controllers/twin_controller.dart';

class TwinScreen extends StatelessWidget {
  final TwinController controller;
  final VoidCallback onBack;

  const TwinScreen({super.key, required this.controller, required this.onBack});

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
                Expanded(child: _buildStageContent(context)),
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
            '트윈 (Twin) · ${controller.partnerMasthead}',
            style: EselTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageContent(BuildContext context) {
    final stage = controller.stage;

    if (stage == TwinStage.revealed || stage == TwinStage.consentWaiting) {
      return _buildRevealedView(context);
    } else if (stage == TwinStage.published) {
      return _buildDoneView(
        '공동 발행 완료 (T10)',
        '두 사람의 표지가 우리들의 한 호로 공동 발행되었습니다.',
      );
    } else if (stage == TwinStage.privateOnly) {
      return _buildDoneView(
        '둘만의 기록으로 저장 (T8private)',
        '이 호는 다른 사람에게 공개되지 않고 둘만의 소중한 기록으로 남습니다.',
      );
    } else if (stage == TwinStage.soloOnly) {
      return _buildDoneView(
        '내 표지만 공개 (T8solo)',
        '상대방의 표지는 비공개로 유지되고 내 표지만 피드에 공개됩니다.',
      );
    }

    return _buildRevealedView(context);
  }

  Widget _buildRevealedView(BuildContext context) {
    final partnerPhoto = controller.visiblePartnerPhoto;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EselTokens.space24),
      child: Column(
        children: [
          const SizedBox(height: EselTokens.space12),
          Text(
            '두 사람의 표지가 열렸습니다 (T6)',
            style: EselTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '공동 발행 시 두 사람의 동의가 필요합니다 (P10).',
            style: EselTypography.bodySmall.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
          const SizedBox(height: EselTokens.space20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(EselTokens.radius16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        EselAssetImage(controller.myPhoto, fit: BoxFit.cover),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Text(
                            '나 (dana)',
                            style: EselTypography.labelSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: EselPaintAsset(
                            paint: controller.myColor,
                            width: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(EselTokens.radius16),
                    child: partnerPhoto != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              EselAssetImage(partnerPhoto, fit: BoxFit.cover),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Text(
                                  controller.partnerMasthead,
                                  style: EselTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: EselPaintAsset(
                                  paint: controller.partnerColor,
                                  width: 24,
                                ),
                              ),
                            ],
                          )
                        : Container(
                            color: EselTokens.paperWarm,
                            child: const Center(
                              child: Text('상대 게시 대기 중 (P08)'),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EselTokens.space20),
          _buildActionButtons(context),
          const SizedBox(height: EselTokens.space20),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (controller.stage == TwinStage.consentWaiting) {
      return Column(
        children: [
          Text(
            '상대방의 동의가 완료되었습니다. 공동 발행에 동의하시겠습니까?',
            style: EselTypography.caption,
          ),
          const SizedBox(height: 12),
          EselButton(
            label: '동의하고 공동 발행하기 (T9)',
            isPrimary: true,
            onTap: controller.giveConsent,
          ),
        ],
      );
    }

    return Column(
      children: [
        EselButton(
          label: '우리의 한 호로 공동 공개 (T7 Joint)',
          isPrimary: true,
          onTap: () => controller.selectVisibility(TwinVisibility.jointPublic),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: EselButton(
                label: '둘만의 기록으로',
                isPrimary: false,
                onTap: () =>
                    controller.selectVisibility(TwinVisibility.privateRecord),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: EselButton(
                label: '내 표지만 공개',
                isPrimary: false,
                onTap: () =>
                    controller.selectVisibility(TwinVisibility.soloPublic),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDoneView(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EselTokens.space32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 56,
            color: EselTokens.ink,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: EselTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: EselTypography.bodyMedium.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
          const SizedBox(height: 30),
          EselButton(
            label: '트윈 홈으로 돌아가기',
            isPrimary: true,
            onTap: controller.reset,
          ),
        ],
      ),
    );
  }
}
