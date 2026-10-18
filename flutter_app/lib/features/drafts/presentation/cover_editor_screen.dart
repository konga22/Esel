import '../../../core/errors/failures.dart';
import '../../garments/presentation/garment_editor.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/design/tokens.g.dart';
import '../../../core/ui/esel_button.dart';
import '../../../core/ui/esel_paint_asset.dart';
import '../../media/domain/models/face_layout_mode.dart';
import '../../media/presentation/cover_preview.dart';
import '../data/local_library.dart';
import '../domain/cover_draft.dart';
import '../../challenges/domain/challenge.dart';
import '../../settings/presentation/device_preferences.dart';

class CoverEditorScreen extends StatefulWidget {
  final LocalLibrary library;
  final CoverDraft? initial;
  final Future<void> Function(CoverDraft)? onPublish;
  final VoidCallback? onClose;
  final List<EselPaint>? candidates;
  const CoverEditorScreen({
    super.key,
    required this.library,
    this.initial,
    this.onPublish,
    this.onClose,
    this.candidates,
  });
  @override
  State<CoverEditorScreen> createState() => _CoverEditorScreenState();
}

class _CoverEditorScreenState extends State<CoverEditorScreen> {
  late CoverDraft _draft;
  late final TextEditingController _masthead, _caption;
  final _capture = GlobalKey();
  final _scroll = ScrollController();
  final _history = <CoverDraft>[];
  bool _busy = false, _dirty = false, _allowPop = false;
  bool _locatingFace = false;
  @override
  void initState() {
    super.initState();
    _draft =
        widget.initial ??
        CoverDraft(
          id: widget.library.newId(),
          photoPath: '',
          updatedAt: DateTime.now(),
        );
    _masthead = TextEditingController(text: _draft.masthead);
    _caption = TextEditingController(text: _draft.caption);
  }

  @override
  void dispose() {
    _masthead.dispose();
    _caption.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _edit(CoverDraft value, {bool history = true}) {
    if (_busy) return;
    if (history) {
      _history.add(_draft);
      if (_history.length > 40) _history.removeAt(0);
    }
    setState(() {
      _draft = value;
      _dirty = true;
    });
  }

  /// 그대로 연출인데 사인을 줄여도 얼굴에 닿는지(P15). 미리보기 표지 360×480 기준.
  bool get _plainTouchesFace =>
      _draft.photoPath.isNotEmpty &&
      CoverPreview.plainMastheadTouchesFace(_draft, const Size(360, 480));

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _draft = _history.removeLast();
      _masthead.text = _draft.masthead;
      _caption.text = _draft.caption;
      _dirty = true;
    });
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        requestFullMetadata: false,
      );
      if (file == null) return;
      final path = widget.library.persistent
          ? await widget.library.importPhoto(file.path)
          : await widget.library.importPhotoBytes(await file.readAsBytes());
      if (!mounted) return;
      await precacheImage(localPhotoProvider(path), context);
      if (!mounted) return;
      _history.add(_draft);
      setState(() {
        _draft = _draft.copyWith(
          photoPath: path,
          faceConfirmed: false,
          garments: _draft.garments.map((g) => g.at(null, null)).toList(),
        );
        _dirty = true;
      });
    } on PlatformException catch (error) {
      _message(
        error.code.contains('denied')
            ? '사진 접근 권한이 필요해요. 기기 설정에서 허용한 뒤 다시 시도해 주세요.'
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

  Future<bool> _save() async {
    if (_busy) return false;
    if (_draft.validationError case final String message) {
      _message(message);
      return false;
    }
    setState(() => _busy = true);
    try {
      await widget.library.save(_draft);
      if (mounted) setState(() => _dirty = false);
      _message('이 기기에 초안을 저장했어요.');
      return true;
    } catch (_) {
      _message('저장하지 못했어요. 기기 저장 공간을 확인해 주세요.');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    if (_busy) return;
    final error = _draft.validationError;
    if (error != null) {
      _message(error);
      return;
    }
    setState(() => _busy = true);
    try {
      if (!await widget.library.photoExists(_draft.photoPath)) {
        throw const FormatException('사진 파일을 찾을 수 없어요. 앨범에서 다시 골라 주세요.');
      }
      await widget.onPublish!(_draft);
      if (mounted) setState(() => _dirty = false);
    } on FormatException catch (error) {
      _message(error.message);
    } on Failure catch (error) {
      _message(error.message);
    } catch (_) {
      _message('올리기 내용을 기기에 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    if (_busy) return;
    if (_dirty) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('편집 중인 초안을 어떻게 할까요?'),
          content: const Text('저장하면 다음에 이어서 편집할 수 있어요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'continue'),
              child: const Text('계속 편집'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              child: const Text('변경 버리기'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: const Text('저장 후 닫기'),
            ),
          ],
        ),
      );
      if (action == null || action == 'continue') return;
      if (action == 'save' && !await _save()) return;
    }
    if (mounted) {
      if (widget.onClose != null) {
        widget.onClose!();
        return;
      }
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _share() async {
    if (_busy) return;
    if (_draft.validationError case final String message) {
      _message(message);
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _busy = true);
    try {
      _scroll.jumpTo(0);
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: 1080 / boundary.size.width,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('image encoding');
      final name = 'esel-${DateTime.now().microsecondsSinceEpoch}.png';
      final png = bytes.buffer.asUint8List();
      final XFile shared;
      final libraryDirectory = widget.library.directory;
      if (libraryDirectory == null) {
        // 웹은 기기 파일이 없으니 바이트 그대로 공유창에 넘긴다.
        shared = XFile.fromData(png, name: name, mimeType: 'image/png');
      } else {
        final directory = Directory('${libraryDirectory.path}/exports');
        await directory.create(recursive: true);
        final file = File('${directory.path}/$name');
        await file.writeAsBytes(png, flush: true);
        shared = XFile(file.path, mimeType: 'image/png');
      }
      await SharePlus.instance.share(
        ShareParams(
          files: [shared],
          title: '${_draft.masthead} 표지',
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      _message('공유창을 열지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fullPreview() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (ctx) => DevicePreferences(
          library: widget.library,
          child: Scaffold(
            backgroundColor: EselColors.paper,
            appBar: AppBar(title: const Text('표지 미리보기')),
            body: Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: CoverPreview(draft: _draft),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _close();
    },
    child: Scaffold(
      backgroundColor: EselColors.paper,
      appBar: AppBar(
        leading: IconButton(
          tooltip: '편집 닫기',
          onPressed: _busy ? null : _close,
          icon: const Icon(Icons.close),
        ),
        title: Text(widget.onPublish == null ? '표지 만들기' : '오늘의 캔버스 만들기'),
        actions: [
          IconButton(
            tooltip: '이전 편집으로 되돌리기',
            onPressed: _busy || _history.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: '전체 미리보기',
            onPressed: _draft.photoPath.isEmpty ? null : _fullPreview,
            icon: const Icon(Icons.fullscreen),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (_draft.challengeId != null) ...[
              Text(
                '${StyleChallenge.resolve(_draft.challengeId)?.title ?? '지난 참여'}에 연결할 오늘의 캔버스',
              ),
              const Text('마감되었거나 다른 주제로 바꾸려면 참여만 해제하고 편집을 계속하세요.'),
              TextButton(
                onPressed: () => _edit(_draft.copyWith(clearChallenge: true)),
                child: const Text('콘텐츠 참여만 해제'),
              ),
            ],
            Text(
              widget.onPublish == null
                  ? '초안은 이 기기에만 보관돼요. 올리기 전까지 공개되지 않아요.'
                  : '로컬 시연 · 올린 호는 이 기기에 저장돼요.',
            ),
            const SizedBox(height: 16),
            if (_locatingFace)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '얼굴 위치 지정 중 · 효과를 숨긴 원본이에요. 사진의 얼굴 가운데를 누르면 효과가 다시 적용돼요.',
                ),
              ),
            RepaintBoundary(
              key: _capture,
              child: CoverPreview(
                draft: _draft,
                editing: _locatingFace || !_draft.faceConfirmed,
                locatingFace: _locatingFace,
                chrome: !_locatingFace,
                onFacePosition: (point) {
                  _edit(
                    _draft.copyWith(faceX: point.dx, faceY: point.dy),
                    history: false,
                  );
                  setState(() => _locatingFace = false);
                },
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                EselButton(
                  label: '사진 선택',
                  icon: Icons.photo_library_outlined,
                  isPrimary: false,
                  onTap: () => _pick(ImageSource.gallery),
                ),
                EselButton(
                  label: '촬영',
                  icon: Icons.camera_alt_outlined,
                  isPrimary: false,
                  onTap: () => _pick(ImageSource.camera),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.onPublish == null)
              TextField(
                key: const Key('draft-masthead'),
                controller: _masthead,
                autocorrect: false,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-z]')),
                ],
                decoration: const InputDecoration(
                  labelText: '사인 · 영문 소문자 2~10자',
                  helperText: '초안의 이름이에요. 계정 이름 중복 확인은 로그인 후 가능해요.',
                ),
                onChanged: (v) => _edit(_draft.copyWith(masthead: v)),
              ),
            Text('사인 크기 · ${(_draft.mastheadScale * 100).round()}%'),
            Slider(
              key: const Key('draft-masthead-scale'),
              value: _draft.mastheadScale,
              min: .5,
              max: 1.4,
              onChangeStart: (_) => _history.add(_draft),
              onChanged: (v) =>
                  _edit(_draft.copyWith(mastheadScale: v), history: false),
            ),
            TextField(
              key: const Key('draft-caption'),
              controller: _caption,
              maxLength: 40,
              maxLines: 2,
              decoration: const InputDecoration(labelText: '표지 문구'),
              onChanged: (v) => _edit(_draft.copyWith(caption: v)),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _draft.caption.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: _draft.caption),
                        );
                        _message('표지 문구를 복사했어요.');
                      },
                icon: const Icon(Icons.copy),
                label: const Text('문구 복사'),
              ),
            ),
            GarmentEditor(
              draft: _draft,
              library: widget.library,
              onChanged: (items) => _edit(_draft.copyWith(garments: items)),
            ),
            const SizedBox(height: 16),
            const Text('초안의 색'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: (widget.candidates ?? EselPaint.values)
                  .map(
                    (color) => ChoiceChip(
                      label: Text(EselPaints.of(color).nameKo),
                      avatar: SizedBox(
                        width: 24,
                        child: EselPaintAsset(paint: color, width: 24),
                      ),
                      selected: _draft.color == color,
                      onSelected: (_) => _edit(_draft.copyWith(color: color)),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('얼굴 자르기 · 하나만 선택해 주세요'),
            Wrap(
              spacing: 6,
              children:
                  [
                        ('그대로', FaceLayoutMode.original),
                        ('사인 뒤로', FaceLayoutMode.behindLogo),
                        ('목 아래', FaceLayoutMode.belowNeck),
                      ]
                      .map(
                        (item) => ChoiceChip(
                          label: Text(item.$1),
                          selected: item.$2 == FaceLayoutMode.original
                              ? faceCropMode(_draft.effectiveFaceEffects) ==
                                    FaceLayoutMode.original
                              : _draft.effectiveFaceEffects.contains(item.$2),
                          onSelected: (_) {
                            setState(() => _locatingFace = false);
                            _edit(
                              _draft.copyWith(
                                faceMode: item.$2,
                                faceEffects: toggleFaceEffect(
                                  _draft.effectiveFaceEffects,
                                  item.$2,
                                ),
                                faceConfirmed: false,
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 8),
            ChoiceChip(
              label: const Text('물감 한 획'),
              selected: _draft.effectiveFaceEffects.contains(
                FaceLayoutMode.paintStroke,
              ),
              onSelected:
                  faceCropMode(_draft.effectiveFaceEffects) ==
                      FaceLayoutMode.belowNeck
                  ? null
                  : (_) {
                      setState(() => _locatingFace = false);
                      _edit(
                        _draft.copyWith(
                          faceEffects: toggleFaceEffect(
                            _draft.effectiveFaceEffects,
                            FaceLayoutMode.paintStroke,
                          ),
                          faceConfirmed: false,
                        ),
                      );
                    },
            ),
            Text(
              _draft.effectiveFaceEffects.contains(FaceLayoutMode.belowNeck)
                  ? '목 아래에서는 물감이 꺼지고 선택할 수 없어요. 그대로 또는 사인 뒤로를 고르면 다시 켤 수 있어요.'
                  : '표지에서 얼굴 가운데를 누르거나 움직여 위치를 정해 주세요.',
            ),
            TextButton(
              onPressed: () {
                setState(() => _locatingFace = !_locatingFace);
                if (_locatingFace) {
                  _scroll.animateTo(
                    0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                  );
                }
              },
              child: Text(_locatingFace ? '효과 미리보기로 돌아가기' : '원본에서 얼굴 위치 맞추기'),
            ),
            if (_plainTouchesFace)
              Text(
                '그대로에서는 사인이 얼굴에 닿아요. 물감 한 획이나 사인 뒤로를 골라 보세요.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            // 얼굴 크기는 물감 폭(얼굴 폭의 2.15배)과 목 아래 자르기(턱 위치)를 함께 정한다.
            const Text('얼굴 크기'),
            Slider(
              semanticFormatterCallback: (v) =>
                  '얼굴 폭 사진의 ${(v * 100).round()}퍼센트',
              value: _draft.faceWidth.clamp(.05, .45),
              min: .05,
              max: .45,
              onChangeStart: (_) => _history.add(_draft),
              onChanged: (v) => _edit(
                _draft.copyWith(faceWidth: v, faceConfirmed: false),
                history: false,
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('얼굴 위치와 연출을 확인했어요'),
              subtitle: const Text('얼굴 연출이 익명화를 보장하지는 않아요.'),
              value: _draft.faceConfirmed,
              onChanged: _draft.photoPath.isEmpty
                  ? null
                  : (v) {
                      if (v == true) setState(() => _locatingFace = false);
                      _edit(_draft.copyWith(faceConfirmed: v ?? false));
                    },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('흰색 사인'),
              subtitle: Text(_draft.whiteTitle ? '흰색' : '잉크색'),
              value: _draft.whiteTitle,
              onChanged: (v) => _edit(_draft.copyWith(whiteTitle: v)),
            ),
            const SizedBox(height: 16),
            EselButton(
              label: _busy ? '처리 중…' : '초안 저장',
              enabled: !_busy,
              onTap: _save,
            ),
            if (widget.onPublish != null) ...[
              const SizedBox(height: 12),
              EselButton(
                label: _busy ? '기기에 저장 중…' : '오늘의 캔버스 올리기',
                enabled: !_busy && _draft.validationError == null,
                onTap: _publish,
              ),
            ],
            const SizedBox(height: 12),
            EselButton(
              label: '표지 이미지 내보내기',
              icon: Icons.ios_share,
              isPrimary: false,
              enabled: !_busy && _draft.validationError == null,
              onTap: _share,
            ),
            const SizedBox(height: 12),
            if (widget.onPublish == null)
              const Text('실제 올리기는 로그인과 서버 연결 후 가능해요.'),
          ],
        ),
      ),
    ),
  );
}
