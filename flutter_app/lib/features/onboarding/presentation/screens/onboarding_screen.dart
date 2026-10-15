import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_button.dart';
import '../../../../core/ui/esel_chip.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../../core/ui/esel_image.dart';
import '../../domain/models/onboarding_draft.dart';
import '../../domain/rules/masthead_rule.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  /// 오늘의 후보 3색(P17).
  final List<EselPaint> candidates;

  const OnboardingScreen({
    super.key,
    required this.controller,
    required this.candidates,
    required this.onCancel,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _nameTextController;

  @override
  void initState() {
    super.initState();
    _nameTextController = TextEditingController(
      text: widget.controller.draft.masthead,
    );
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final draft = widget.controller.draft;
        return Scaffold(
          backgroundColor: EselTokens.paper,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(draft.step),
                Expanded(child: _buildStepContent(draft)),
                _buildBottomBar(draft),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EselTokens.space20,
        vertical: EselTokens.space12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (step != OnboardingStep.color && step != OnboardingStep.done)
            EselPressable(
              onTap: widget.controller.prevStep,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: EselTokens.ink,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
          Text(
            _getStepTitle(step),
            style: EselTypography.labelMedium.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
          if (step != OnboardingStep.done)
            EselPressable(
              onTap: widget.onCancel,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.close, size: 22, color: EselTokens.inkSubtle),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  String _getStepTitle(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.color:
        return '1 / 4 · 창간호의 색';
      case OnboardingStep.shoot:
        return '2 / 4 · 사진';
      case OnboardingStep.name:
        return '3 / 4 · 제호';
      case OnboardingStep.face:
        return '4 / 4 · 얼굴 연출';
      case OnboardingStep.done:
        return '창간 완료';
    }
  }

  Widget _buildStepContent(OnboardingDraft draft) {
    switch (draft.step) {
      case OnboardingStep.color:
        return _buildColorStep(draft);
      case OnboardingStep.shoot:
        return _buildShootStep(draft);
      case OnboardingStep.name:
        return _buildNameStep(draft);
      case OnboardingStep.face:
        return _buildFaceStep(draft);
      case OnboardingStep.done:
        return _buildDoneStep(draft);
    }
  }

  Widget _buildColorStep(OnboardingDraft draft) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EselTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: EselTokens.space20),
          Text(
            '오늘의 후보 중에서\n창간호의 색을 골라주세요.',
            style: EselTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: EselTokens.space8),
          Text(
            '발행된 오늘 호의 색은 하루 동안 변경할 수 없습니다.',
            style: EselTypography.bodyMedium.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
          const SizedBox(height: EselTokens.space40),
          ...widget.candidates.map((c) {
            final isSelected = draft.color == c;
            return Padding(
              padding: const EdgeInsets.only(bottom: EselTokens.space16),
              child: EselPressable(
                onTap: () => widget.controller.selectColor(c),
                child: Container(
                  padding: const EdgeInsets.all(EselTokens.space16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? EselTokens.paperWarm
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(EselTokens.radius16),
                    border: Border.all(
                      color: isSelected
                          ? EselTokens.ink
                          : EselTokens.borderDefault,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      EselPaintAsset(paint: c, width: 44),
                      const SizedBox(width: EselTokens.space16),
                      Text(
                        EselPaints.of(c).nameKo,
                        style: EselTypography.bodyLarge.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: EselTokens.ink,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShootStep(OnboardingDraft draft) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EselTokens.space24),
      child: Column(
        children: [
          const SizedBox(height: EselTokens.space12),
          Text(
            '오늘을 담은 사진 한 장',
            style: EselTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: EselTokens.space6),
          Text(
            '얼굴이나 분위기가 담긴 사진을 골라주세요.',
            style: EselTypography.bodySmall.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
          const SizedBox(height: EselTokens.space20),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(EselTokens.radius20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    draft.photoAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: EselTokens.paperWarm,
                      child: const Center(
                        child: Icon(
                          Icons.photo_size_select_actual_outlined,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: EselTokens.space20,
                    right: EselTokens.space20,
                    child: EselButton(
                      label: '다른 사진 선택',
                      isPrimary: false,
                      icon: Icons.refresh_rounded,
                      onTap: widget.controller.cycleNextPhoto,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: EselTokens.space16),
        ],
      ),
    );
  }

  Widget _buildNameStep(OnboardingDraft draft) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EselTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: EselTokens.space20),
          Text(
            '나만의 잡지 제호를 정하세요.',
            style: EselTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: EselTokens.space8),
          Text(
            '영문 소문자 2–10자 (소문자 a–z만 허용)',
            style: EselTypography.bodyMedium.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
          const SizedBox(height: EselTokens.space32),
          TextField(
            controller: _nameTextController,
            autofocus: true,
            style: EselTypography.headlineMedium.copyWith(letterSpacing: 2),
            onChanged: (val) {
              widget.controller.updateMasthead(val);
              // Ensure sanitized text stays in sync if filtered
              if (_nameTextController.text !=
                  widget.controller.draft.masthead) {
                _nameTextController.value = TextEditingValue(
                  text: widget.controller.draft.masthead,
                  selection: TextSelection.collapsed(
                    offset: widget.controller.draft.masthead.length,
                  ),
                );
              }
            },
            decoration: InputDecoration(
              hintText: 'esel',
              filled: true,
              fillColor: EselTokens.paperWarm,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(EselTokens.radius14),
                borderSide: BorderSide.none,
              ),
              suffixIcon: draft.isNameAvailable
                  ? const Icon(
                      Icons.check_circle_outline,
                      color: EselTokens.semanticGreen,
                    )
                  : const Icon(
                      Icons.error_outline,
                      color: EselTokens.semanticRed,
                    ),
            ),
          ),
          const SizedBox(height: EselTokens.space12),
          if (draft.isNameAvailable)
            Text(
              '쓸 수 있는 이름이에요.',
              style: EselTypography.caption.copyWith(
                color: EselTokens.semanticGreen,
              ),
            )
          else
            Text(
              '이미 사용 중이거나 올바르지 않은 제호입니다.',
              style: EselTypography.caption.copyWith(
                color: EselTokens.semanticRed,
              ),
            ),
          const SizedBox(height: EselTokens.space40),
          Center(
            child: Text(
              draft.masthead.isEmpty ? 'Esel' : draft.masthead,
              style: EselTypography.mastheadHero.copyWith(
                fontSize: MastheadRule.calculateFontSize(draft.masthead),
                color: EselTokens.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceStep(OnboardingDraft draft) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EselTokens.space24),
      child: Column(
        children: [
          const SizedBox(height: EselTokens.space12),
          Text(
            '얼굴 연출 선택',
            style: EselTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: EselTokens.space6),
          Text(
            '표지에서 얼굴이 보여지는 방식을 정하세요.',
            style: EselTypography.bodySmall.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
          const SizedBox(height: EselTokens.space16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(EselTokens.radius20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EselAssetImage(draft.photoAsset, fit: BoxFit.cover),
                  if (draft.faceMode == FaceLayoutMode.paintStroke &&
                      draft.color != null)
                    Positioned(
                      top: 130,
                      left: 100,
                      child: Opacity(
                        opacity: 0.88,
                        child: EselPaintAsset(paint: draft.color!, width: 100),
                      ),
                    ),
                  Positioned(
                    top: 40,
                    left: 20,
                    right: 20,
                    child: Text(
                      draft.masthead,
                      textAlign: TextAlign.center,
                      style: EselTypography.mastheadHero.copyWith(
                        fontSize: 64,
                        color: draft.faceMode == FaceLayoutMode.behindLogo
                            ? Colors.white70
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: EselTokens.space16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFaceChip('그대로', FaceLayoutMode.original, draft.faceMode),
                const SizedBox(width: EselTokens.space8),
                _buildFaceChip(
                  '물감 살짝',
                  FaceLayoutMode.paintStroke,
                  draft.faceMode,
                ),
                const SizedBox(width: EselTokens.space8),
                _buildFaceChip(
                  '제호 뒤로',
                  FaceLayoutMode.behindLogo,
                  draft.faceMode,
                ),
                const SizedBox(width: EselTokens.space8),
                _buildFaceChip(
                  '목 아래',
                  FaceLayoutMode.belowNeck,
                  draft.faceMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceChip(
    String label,
    FaceLayoutMode mode,
    FaceLayoutMode current,
  ) {
    final isSelected = mode == current;
    return EselChip(
      label: label,
      isActive: isSelected,
      onTap: () => widget.controller.selectFaceMode(mode),
    );
  }

  Widget _buildDoneStep(OnboardingDraft draft) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EselTokens.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: EselTokens.paperWarm,
              borderRadius: BorderRadius.circular(EselTokens.radiusPill),
            ),
            child: Text('Nº 001 · 창간호', style: EselTypography.monoSmall),
          ),
          const SizedBox(height: EselTokens.space24),
          Text(
            draft.masthead,
            style: EselTypography.mastheadHero.copyWith(
              fontSize: MastheadRule.calculateFontSize(draft.masthead),
            ),
          ),
          const SizedBox(height: EselTokens.space16),
          Text(
            '축하합니다! 당신만의 잡지가 창간되었습니다.\n오늘부터 매일 하루 한 호를 발행해 보세요.',
            textAlign: TextAlign.center,
            style: EselTypography.bodyMedium.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(OnboardingDraft draft) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EselTokens.space24,
        vertical: EselTokens.space16,
      ),
      child: EselButton(
        label: draft.step == OnboardingStep.done
            ? '내 잡지 시작하기'
            : (draft.step == OnboardingStep.face ? '창간호 발행 (Nº 001)' : '다음'),
        isPrimary: true,
        onTap: draft.step == OnboardingStep.done
            ? widget.onComplete
            : widget.controller.nextStep,
      ),
    );
  }
}
