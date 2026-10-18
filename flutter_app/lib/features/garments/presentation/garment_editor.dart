import 'package:flutter/material.dart';
import '../../../core/design/typography.dart';
import '../../../core/ui/esel_paint_asset.dart';
import '../../drafts/data/local_library.dart';
import '../../drafts/domain/cover_draft.dart';
import '../../media/presentation/photo_ratio_builder.dart';
import '../domain/garment.dart';

class GarmentEditor extends StatelessWidget {
  final CoverDraft draft;
  final LocalLibrary library;
  final ValueChanged<List<Garment>> onChanged;
  const GarmentEditor({
    super.key,
    required this.draft,
    required this.library,
    required this.onChanged,
  });
  Future<void> _edit(BuildContext context, [Garment? original]) async {
    final name = TextEditingController(text: original?.name ?? '');
    var kind = original?.kind ?? Garment.kinds.first,
        note = original?.note ?? '';
    var today = original?.todayColor ?? false;
    var x = original?.x, y = original?.y;
    final result = await showModalBottomSheet<Garment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('착용 정보 더하기', style: EselTypography.heading(fontSize: 28)),
                const Text('옷 종류만 골라도 돼요. 가격이나 링크는 넣지 않아요.'),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final item in Garment.kinds)
                      ChoiceChip(
                        label: Text(item),
                        selected: kind == item,
                        onSelected: (_) => update(() => kind = item),
                      ),
                  ],
                ),
                TextField(
                  controller: name,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: '이름 · 브랜드는 선택이에요',
                    helperText: '가격이나 링크 대신 옷 이름을 적어 주세요.',
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final item in Garment.notes)
                      FilterChip(
                        label: Text(item),
                        selected: note == item,
                        onSelected: (_) =>
                            update(() => note = note == item ? '' : item),
                      ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('오늘의 색 옷'),
                  subtitle: const Text('선택한 캔버스 색의 물감 칩을 붙여요.'),
                  value: today,
                  onChanged: (v) => update(() => today = v),
                ),
                if (draft.photoPath.isNotEmpty) ...[
                  const Text('원본 사진에서 옷 위치를 눌러 주세요. 위치는 선택이에요.'),
                  PhotoRatioBuilder(
                    image: localPhotoProvider(draft.photoPath),
                    builder: (context, ratio) => AspectRatio(
                      aspectRatio: 1 / ratio,
                      child: LayoutBuilder(
                        builder: (context, box) => GestureDetector(
                          key: const Key('garment-position-photo'),
                          onTapUp: (details) => update(() {
                            x = (details.localPosition.dx / box.maxWidth).clamp(
                              0,
                              1,
                            );
                            y = (details.localPosition.dy / box.maxHeight)
                                .clamp(0, 1);
                          }),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image(
                                image: localPhotoProvider(draft.photoPath),
                                fit: BoxFit.fill,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Text('사진 파일을 찾지 못했어요.'),
                                ),
                              ),
                              if (x != null && y != null)
                                Positioned(
                                  left: x! * box.maxWidth - 16,
                                  top: y! * box.maxHeight - 16,
                                  child: const Icon(
                                    Icons.radio_button_checked,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => update(() {
                      x = null;
                      y = null;
                    }),
                    child: const Text('위치 지우기'),
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(
                          context,
                          Garment(
                            id: original?.id ?? library.newId(),
                            kind: kind,
                            name: name.text.trim(),
                            note: note,
                            todayColor: today,
                            x: x,
                            y: y,
                          ),
                        ),
                        child: const Text('더하기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // 시트가 닫히는 애니메이션 동안 TextField가 컨트롤러를 읽는다.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    if (result != null && context.mounted) {
      final next = [...draft.garments];
      if (original == null) {
        next.add(result);
      } else {
        next[next.indexWhere((v) => v.id == original.id)] = result;
      }
      onChanged(List.unmodifiable(next));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('착용 정보', style: EselTypography.heading(fontSize: 26)),
      for (final garment in draft.garments)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: garment.todayColor
              ? EselPaintAsset(paint: draft.color, width: 28)
              : const Icon(Icons.checkroom),
          title: Text(garment.label),
          subtitle: Text(
            [
              garment.kind,
              garment.note,
              if (garment.x != null) '사진 위치 있음',
            ].where((s) => s.isNotEmpty).join(' · '),
          ),
          onTap: () => _edit(context, garment),
          trailing: IconButton(
            tooltip: '착용 정보 삭제',
            onPressed: () => onChanged(
              draft.garments.where((v) => v.id != garment.id).toList(),
            ),
            icon: const Icon(Icons.close),
          ),
        ),
      if (draft.garments.length < 8) ...[
        TextButton.icon(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add),
          label: const Text('착용 정보 더하기'),
        ),
        if (library
            .garmentsFor(draft.ownerId)
            .where((v) => !draft.garments.any((g) => g.id == v.id))
            .isNotEmpty)
          TextButton(
            onPressed: () async {
              final selected = await showModalBottomSheet<Garment>(
                context: context,
                useSafeArea: true,
                builder: (context) => ListView(
                  children: [
                    const ListTile(title: Text('내 옷에서 고르기 · 같은 옷, 다른 코디')),
                    for (final item
                        in library
                            .garmentsFor(draft.ownerId)
                            .where(
                              (v) => !draft.garments.any((g) => g.id == v.id),
                            ))
                      ListTile(
                        title: Text(item.label),
                        subtitle: Text(item.kind),
                        onTap: () => Navigator.pop(
                          context,
                          item.at(null, null).forColor(false),
                        ),
                      ),
                  ],
                ),
              );
              if (selected != null && context.mounted) {
                onChanged([...draft.garments, selected]);
              }
            },
            child: const Text('내 옷에서 고르기'),
          ),
      ],
      const Text('선택 사항 · 한 캔버스에 8개까지'),
    ],
  );
}
