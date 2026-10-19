import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/time/service_date.dart';
import '../../../../core/ui/esel_button.dart';
import '../../../../core/ui/esel_glass.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../drafts/data/local_library.dart';
import '../../../media/presentation/cover_preview.dart';
import '../../../media/presentation/face_adjust_guide.dart';
import '../../domain/models/onboarding_draft.dart';
import '../controllers/onboarding_controller.dart';

/// 사진을 골라 기기 보관함에 들이고 그 경로를 돌려준다. 취소하면 null.
typedef PickFoundingPhoto = Future<String?> Function(ImageSource source);

/// 첫 캔버스 J3~J7: 색 → 촬영 → 사인 → 얼굴 → 첫 캔버스(P13).
///
/// 한 화면에 결정 하나, 각 단계에 뒤로가기. 첫 캔버스 올리기를 누르면 [onFound]가 계정·사인을
/// 정하고 Nº 001을 실제로 올린 뒤 [OnboardingController.markFounded]로 J7을 연다.
class OnboardingScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onCancel;

  /// 계정을 확인하고 사인을 정한 뒤 첫 캔버스를 올린다.
  final Future<void> Function() onFound;
  final VoidCallback onOpenFeed;
  final VoidCallback onOpenMyMagazine;

  /// 오늘의 후보 3색(P17).
  final List<EselPaint> candidates;
  final ServiceDate today;
  final LocalLibrary library;

  /// 테스트에서 사진 고르기를 바꿔 끼운다. 기본은 카메라·앨범(image_picker).
  final PickFoundingPhoto? pickPhoto;

  const OnboardingScreen({
    super.key,
    required this.controller,
    required this.candidates,
    required this.today,
    required this.library,
    required this.onCancel,
    required this.onFound,
    required this.onOpenFeed,
    required this.onOpenMyMagazine,
    this.pickPhoto,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _name;
  bool _busy = false;
  bool _locatingFace = false;
  final _facePreviewKey = GlobalKey();

  OnboardingController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _c.draft.masthead);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String?> _defaultPick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      requestFullMetadata: false,
      maxWidth: 2160,
      maxHeight: 2160,
    );
    if (file == null) return null;
    return widget.library.persistent
        ? widget.library.importPhoto(file.path)
        : widget.library.importPhotoBytes(await file.readAsBytes());
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await (widget.pickPhoto ?? _defaultPick)(source);
      if (path == null || !mounted) return;
      _c.setPhoto(path);
      _c.nextStep();
    } on PlatformException catch (error) {
      _message(
        error.code.contains('denied')
            ? '카메라·사진 접근 권한이 필요해요. 기기 설정에서 허용한 뒤 다시 시도해 주세요.'
            : '사진을 열지 못했어요. 다시 시도해 주세요.',
      );
    } on FormatException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('사진을 저장하지 못했어요. 기기 저장 공간을 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _found() async {
    if (_busy || !_c.canProceed()) return;
    setState(() => _busy = true);
    try {
      await widget.onFound();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() {
    if (_c.currentStep == OnboardingStep.color) {
      widget.onCancel();
    } else {
      _c.prevStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final draft = _c.draft;
        return switch (draft.step) {
          OnboardingStep.color => _buildColor(draft),
          OnboardingStep.shoot => _buildShoot(draft),
          OnboardingStep.name => _buildName(draft),
          OnboardingStep.face => _buildFace(draft),
          OnboardingStep.done => _buildDone(draft),
        };
      },
    );
  }

  // ───────── 공통

  EselPaint _colorOf(OnboardingDraft draft) =>
      draft.color ?? widget.candidates.first;

  Widget _page({
    required int step,
    required List<Widget> children,
    required Widget bottom,
  }) {
    return Scaffold(
      backgroundColor: EselColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepHeader(step: step, onBack: _back),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: children,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: bottom,
            ),
          ],
        ),
      ),
    );
  }

  Widget _primary(String label, {required bool enabled, VoidCallback? onTap}) {
    return EselButton(
      label: label,
      width: double.infinity,
      enabled: enabled && !_busy,
      onTap: onTap,
    );
  }

  // ───────── J3 첫 캔버스의 색

  Widget _buildColor(OnboardingDraft draft) {
    final picked = _colorOf(draft);
    final name = EselPaints.of(picked).nameKo;
    return _page(
      step: 1,
      children: [
        const SizedBox(height: 26),
        Text(
          '${widget.today.label} 오늘의 색',
          style: EselTypography.meta(fontSize: 12),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            '첫 캔버스는\n어떤 색으로 할까요?',
            style: EselTypography.heading(fontSize: 36).copyWith(height: 1.2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '고른 색의 옷·양말·가방 무엇이든 좋아요. 그 색으로 첫 표지를 찍어요.',
          style: EselTypography.body(
            color: EselColors.sub,
          ).copyWith(height: 1.55),
        ),
        const SizedBox(height: 26),
        for (final color in widget.candidates) ...[
          _ColorChoice(
            color: color,
            selected: color == picked,
            onTap: () => _c.selectColor(color),
          ),
          const SizedBox(height: 10),
        ],
      ],
      bottom: _primary(
        '${_withParticle(name, '로', '으로')} 찍기',
        enabled: true,
        onTap: () {
          if (draft.color == null) _c.selectColor(picked);
          _c.nextStep();
        },
      ),
    );
  }

  // ───────── J4 촬영

  Widget _buildShoot(OnboardingDraft draft) {
    final color = _colorOf(draft);
    final hasPhoto = draft.photoPath.isNotEmpty;
    final name = EselPaints.of(color).nameKo;
    return Scaffold(
      backgroundColor: const Color(0xFF111210),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPhoto)
            Image(
              image: localPhotoProvider(draft.photoPath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          const _Shade(top: true, height: 200, opacity: 0.5),
          const _Shade(top: false, height: 280, opacity: 0.65),
          SafeArea(
            child: Column(
              children: [
                _StepHeader(step: 2, onBack: _back, onPhoto: true),
                const SizedBox(height: 10),
                EselGlass(
                  height: 44,
                  borderRadius: 22,
                  padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EselPaintAsset(paint: color, width: 52),
                      const SizedBox(width: 4),
                      Text(
                        '${_withParticle(name, '가', '이')} 보이게 찍어요',
                        style: EselTypography.label(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: hasPhoto
                      ? const SizedBox.shrink()
                      : Center(
                          child: Container(
                            width: 325,
                            margin: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0x8CFFFFFF),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                ),
                Text(
                  '얼굴은 다음 단계에서 가릴 수 있어요.',
                  style: EselTypography.body(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      EselPressable(
                        semanticsLabel: '앨범에서 고르기',
                        onTap: () => _pick(ImageSource.gallery),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      EselPressable(
                        semanticsLabel: '촬영',
                        onTap: () => _pick(ImageSource.camera),
                        child: Container(
                          width: 82,
                          height: 82,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Container(
                            width: 66,
                            height: 66,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // 찍은 사진이 있으면 다시 찍지 않고 다음으로.
                      hasPhoto
                          ? EselPressable(
                              semanticsLabel: '이 사진으로 다음',
                              onTap: _c.nextStep,
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0x2EFFFFFF),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const SizedBox(width: 52, height: 52),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────── J5 사인

  Widget _buildName(OnboardingDraft draft) {
    final shown = draft.masthead.isEmpty ? 'esel' : draft.masthead;
    final (hint, isError) = switch (draft.mastheadStatus) {
      MastheadStatus.tooShort => ('영문 소문자 2~10자로 적어요.', false),
      MastheadStatus.checking => ('쓸 수 있는 이름인지 확인하고 있어요.', false),
      MastheadStatus.available => ('${draft.masthead} — 쓸 수 있는 이름이에요.', false),
      MastheadStatus.taken => ('이미 있는 이름이에요. 다른 이름을 적어 주세요.', true),
      MastheadStatus.unknown => ('이름을 확인하지 못했어요. 잠시 뒤 다시 적어 주세요.', true),
    };
    return _page(
      step: 3,
      children: [
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            '사인을 정해요',
            style: EselTypography.heading(fontSize: 30).copyWith(height: 1.2),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: _CoverFrame(
            width: 260,
            height: 386,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _photo(draft.photoPath),
                const _Shade(top: true, fraction: 0.45, opacity: 0.4),
                const Positioned(
                  left: 10,
                  right: 10,
                  top: 8,
                  child: _MetaRow(
                    left: 'ESEL',
                    right: 'Nº 001 · 첫 캔버스',
                    fontSize: 8,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 20,
                  child: _Masthead(
                    text: shown,
                    width: 260,
                    max: 140,
                    scale: draft.mastheadScale,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('사인 크기 · ${(draft.mastheadScale * 100).round()}%'),
        Slider(
          key: const Key('founding-masthead-scale'),
          value: draft.mastheadScale,
          min: .5,
          max: 1.4,
          semanticFormatterCallback: (v) => '사인 크기 ${(v * 100).round()}퍼센트',
          onChanged: _c.setMastheadScale,
        ),
        Text(
          '영문 닉네임 · 표지 사인이 돼요',
          style: EselTypography.body(fontSize: 12, color: EselColors.muted),
        ),
        TextField(
          key: const Key('founding-masthead'),
          controller: _name,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.none,
          inputFormatters: [
            TextInputFormatter.withFunction((old, next) {
              final clean = _c.updateMasthead(next.text);
              return TextEditingValue(
                text: clean,
                selection: TextSelection.collapsed(offset: clean.length),
              );
            }),
          ],
          style: EselTypography.heading(fontSize: 28).copyWith(height: 1.2),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: EselColors.ink, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: EselColors.ink, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          style: EselTypography.body(
            fontSize: 13,
            color: isError ? EselColors.error : EselColors.muted,
          ),
        ),
      ],
      bottom: _primary('다음', enabled: _c.canProceed(), onTap: _c.nextStep),
    );
  }

  // ───────── J6 얼굴

  /// 원본에서 얼굴 가운데를 고르는 모드로. 표지가 보이게 올려 준다.
  void _locateFace() {
    setState(() => _locatingFace = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final preview = _facePreviewKey.currentContext;
      if (mounted && preview != null) {
        Scrollable.ensureVisible(
          preview,
          duration: const Duration(milliseconds: 180),
        );
      }
    });
  }

  Widget _buildFace(OnboardingDraft draft) {
    final cover = draft.toCover(id: 'founding', now: DateTime(2026));
    return _page(
      step: 4,
      children: [
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            '얼굴은 어떻게 할까요?',
            style: EselTypography.heading(fontSize: 30).copyWith(height: 1.2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '호마다 바꿀 수 있어요. 가려도 표지는 똑같이 멋져요.',
          style: EselTypography.body(fontSize: 14, color: EselColors.sub),
        ),
        const SizedBox(height: 20),
        Center(
          child: _CoverFrame(
            width: 210,
            height: 310,
            child: CoverPreview(
              key: _facePreviewKey,
              draft: cover,
              editing: _locatingFace,
              locatingFace: _locatingFace,
              aspectRatio: null,
              chrome: !_locatingFace,
              hint: _locatingFace ? '얼굴 가운데를 눌러 주세요' : null,
              onFacePosition: (point) {
                _c.placeFace(point);
                setState(() => _locatingFace = false);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 물감이 어긋났을 때 무엇을 누를지 표지 바로 아래에서 알려 준다(PR #21 리뷰).
        FaceAdjustGuide(
          effects: draft.effectiveFaceEffects,
          locating: _locatingFace,
          placed: draft.facePlaced,
          cancelHere: false,
          onToggle: _locateFace,
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 172 / 64,
          children: [
            for (final (mode, title, sub) in const [
              (FaceLayoutMode.original, '그대로', '얼굴을 보여요'),
              (FaceLayoutMode.behindLogo, '사인 뒤로', '이름 뒤에 숨겨요'),
              (FaceLayoutMode.belowNeck, '목 아래', '옷만 보여요'),
            ])
              _FaceCard(
                title: title,
                sub: sub,
                selected: mode == FaceLayoutMode.original
                    ? faceCropMode(draft.effectiveFaceEffects) ==
                          FaceLayoutMode.original
                    : draft.effectiveFaceEffects.contains(mode),
                onTap: () {
                  setState(() => _locatingFace = false);
                  _c.selectFaceMode(mode);
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        _FaceCard(
          title: '물감 한 획',
          sub: '오늘의 색으로 가려요',
          selected: draft.effectiveFaceEffects.contains(
            FaceLayoutMode.paintStroke,
          ),
          onTap:
              faceCropMode(draft.effectiveFaceEffects) ==
                  FaceLayoutMode.belowNeck
              ? null
              : () {
                  setState(() => _locatingFace = false);
                  _c.selectFaceMode(FaceLayoutMode.paintStroke);
                },
        ),
        const SizedBox(height: 8),
        const Text('얼굴 크기'),
        Slider(
          value: draft.faceWidth,
          min: .05,
          max: .45,
          semanticFormatterCallback: (v) => '얼굴 폭 사진의 ${(v * 100).round()}퍼센트',
          onChanged: _c.setFaceWidth,
        ),
        if (draft.effectiveFaceEffects.contains(FaceLayoutMode.belowNeck))
          const Text(
            '목 아래에서는 물감이 꺼지고 선택할 수 없어요. 물감을 쓰려면 그대로 또는 사인 뒤로를 골라 주세요. 옷이 부족하면 다른 사진을 골라 주세요.',
          ),
        const Text('얼굴 연출이 익명화를 보장하지는 않아요.'),
      ],
      bottom: _primary(
        _locatingFace
            ? '위치 조정 취소'
            : _busy
            ? '첫 캔버스를 올리는 중…'
            : '첫 캔버스 올리기',
        enabled: _locatingFace || _c.canProceed(),
        onTap: _locatingFace
            ? () => setState(() => _locatingFace = false)
            : _found,
      ),
    );
  }

  // ───────── J7 첫 캔버스

  Widget _buildDone(OnboardingDraft draft) {
    final issue = draft.issue!;
    final info = EselPaints.of(issue.color);
    return Scaffold(
      backgroundColor: const Color(0xFFD9D2C6),
      body: LayoutBuilder(
        builder: (context, box) {
          final top = MediaQuery.paddingOf(context).top;
          return Stack(
            fit: StackFit.expand,
            children: [
              CoverPreview(draft: issue, aspectRatio: null, chrome: false),
              const _Shade(top: true, height: 340, opacity: 0.42),
              const _Shade(top: false, height: 420, opacity: 0.7),
              Positioned(
                left: 20,
                right: 20,
                top: top + 4,
                child: _MetaRow(
                  left: 'ESEL',
                  right: 'Nº 001 · 첫 캔버스 · ${widget.today.label}',
                  fontSize: 12,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: top + 30,
                child: _Masthead(
                  text: issue.masthead,
                  width: box.maxWidth,
                  max: 200,
                  scale: issue.mastheadScale,
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.paddingOf(context).bottom + 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '첫 캔버스를 축하해요',
                      style: EselTypography.meta(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${issue.masthead}의 첫 호가\n오늘 팔레트에 올라갔어요.',
                      style: EselTypography.heading(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        EselPaintAsset(paint: issue.color, width: 56),
                        const SizedBox(width: 8),
                        Text(
                          '${info.nameKo} · 같은 색 ${draft.sameColorCount}명과 함께',
                          style: EselTypography.label(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    EselPressable(
                      semanticsLabel: '오늘의 표지 보러 가기',
                      onTap: widget.onOpenFeed,
                      child: Container(
                        height: EselSizes.button,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: EselColors.paper,
                          borderRadius: BorderRadius.circular(
                            EselSizes.button / 2,
                          ),
                        ),
                        child: Text(
                          '오늘의 표지 보러 가기',
                          style: EselTypography.label(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    EselPressable(
                      semanticsLabel: '스케치북 보기',
                      onTap: widget.onOpenMyMagazine,
                      child: SizedBox(
                        height: 48,
                        child: Center(
                          child: Text(
                            '스케치북 보기',
                            style: EselTypography.label(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _photo(String path) => path.isEmpty
      ? const ColoredBox(color: EselColors.photo)
      : Image(
          image: localPhotoProvider(path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(color: EselColors.photo),
        );

  /// 받침이 있으면 [withFinal], 없으면(또는 ㄹ 받침 + 로) [withoutFinal].
  static String _withParticle(
    String word,
    String withoutFinal,
    String withFinal,
  ) {
    final last = word.codeUnitAt(word.length - 1) - 0xAC00;
    if (last < 0 || last > 11171) return '$word$withoutFinal';
    final jong = last % 28;
    if (jong == 0) return '$word$withoutFinal';
    if (withoutFinal == '로' && jong == 8) return '$word$withoutFinal';
    return '$word$withFinal';
  }
}

class _StepHeader extends StatelessWidget {
  final int step;
  final VoidCallback onBack;
  final bool onPhoto;

  const _StepHeader({
    required this.step,
    required this.onBack,
    this.onPhoto = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = onPhoto ? Colors.white : EselColors.ink;
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 6),
              EselPressable(
                semanticsLabel: '이전',
                onTap: onBack,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.arrow_back_ios_new, size: 20, color: fg),
                ),
              ),
              const Spacer(),
              Text('첫 캔버스 $step / 4', style: EselTypography.meta(color: fg)),
              const SizedBox(width: 18),
            ],
          ),
        ),
        if (!onPhoto)
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (var i = 1; i <= 4; i++) ...[
                    if (i > 1) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: i <= step ? EselColors.ink : EselColors.line,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ColorChoice extends StatelessWidget {
  final EselPaint color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = EselPaints.of(color);
    return Semantics(
      selected: selected,
      child: EselPressable(
        semanticsLabel: info.nameKo,
        onTap: onTap,
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(EselRadius.colorPick),
            border: Border.all(
              color: selected ? EselColors.ink : EselColors.hairline,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14292A27),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                EselPaintAsset(paint: color, width: 120),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.nameKo,
                      style: EselTypography.label(fontSize: 18),
                    ),
                    Text(
                      info.nameEn,
                      style: EselTypography.name(
                        fontSize: 16,
                        color: EselColors.muted,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? EselColors.ink : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: EselColors.paper,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaceCard extends StatelessWidget {
  final String title;
  final String sub;
  final bool selected;
  final VoidCallback? onTap;

  const _FaceCard({
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = onTap == null
        ? EselColors.muted
        : selected
        ? EselColors.paper
        : EselColors.ink;
    return Semantics(
      selected: selected,
      child: EselPressable(
        semanticsLabel: '$title · $sub',
        enabled: onTap != null,
        onTap: onTap,
        child: Container(
          height: 64,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? EselColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(EselRadius.card),
            border: Border.all(color: EselColors.ink, width: 1.5),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: EselTypography.label(fontSize: 15, color: fg),
                ),
                Text(
                  sub,
                  style: EselTypography.body(
                    fontSize: 12,
                    color: fg.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 미리보기 표지 틀(디자인: 그림자 0 14 36 rgba(41,42,39,0.2)).
class _CoverFrame extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const _CoverFrame({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    clipBehavior: Clip.hardEdge,
    decoration: const BoxDecoration(
      color: EselColors.photo,
      boxShadow: [
        BoxShadow(
          color: Color(0x33292A27),
          blurRadius: 36,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: child,
  );
}

class _Masthead extends StatelessWidget {
  final String text;
  final double width;
  final double max;
  final double scale;

  const _Masthead({
    required this.text,
    required this.width,
    required this.max,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: EselTypography.masthead(
          fontSize:
              EselTypography.mastheadSize(
                text,
                width,
                max: max,
              ).floorToDouble() *
              scale,
          color: Colors.white,
        ),
      ),
    ),
  );
}

class _MetaRow extends StatelessWidget {
  final String left;
  final String right;
  final double fontSize;

  const _MetaRow({
    required this.left,
    required this.right,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final style = EselTypography.meta(fontSize: fontSize, color: Colors.white);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(left, style: style),
        Text(right, style: style),
      ],
    );
  }
}

/// 사진 위 글자를 위한 그림자(위·아래).
class _Shade extends StatelessWidget {
  final bool top;
  final double? height;
  final double? fraction;
  final double opacity;

  const _Shade({
    required this.top,
    this.height,
    this.fraction,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Colors.black.withValues(alpha: opacity);
    final shade = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: top ? [dark, Colors.transparent] : [Colors.transparent, dark],
        ),
      ),
    );
    return Align(
      alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
      child: fraction != null
          ? FractionallySizedBox(
              widthFactor: 1,
              heightFactor: fraction,
              child: shade,
            )
          : SizedBox(width: double.infinity, height: height, child: shade),
    );
  }
}
