import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/time/service_date.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../data/sources/records_source.dart';
import '../../domain/models/server_records.dart';

class MonthlyRecordScreen extends StatefulWidget {
  final RecordsSource source;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenIssue;
  const MonthlyRecordScreen({
    super.key,
    required this.source,
    required this.onBack,
    required this.onOpenIssue,
  });
  @override
  State<MonthlyRecordScreen> createState() => _MonthlyRecordScreenState();
}

class _MonthlyRecordScreenState extends State<MonthlyRecordScreen> {
  RecordsSource get source => widget.source;
  ServerMonthRecords? _records;
  ServiceDate? _today;
  DateTime? _month;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([int delta = 0]) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _records = null;
      if (_month != null) {
        _month = DateTime.utc(_month!.year, _month!.month + delta);
      }
    });
    try {
      final today = await source.today();
      if (!mounted) return;
      final target = _month ?? DateTime.utc(today.year, today.month);
      _month = target;
      final key = '${target.year}-${target.month.toString().padLeft(2, '0')}';
      final records = await source.month(key);
      if (mounted) {
        setState(() {
          _records = records;
          _today = today;
          _month = target;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is Failure ? e.message : '색 기록을 불러오지 못했어요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(ServiceDate date) async {
    EselPaint? color;
    String? error;
    bool saving = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: Text('${date.shortLabel} 색 복원'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '사진 없이 나만 보는 색 기록을 채워요. 올리기 호수와 공개 잠금은 바뀌지 않아요. 선택한 날의 후보에 없는 색은 서버에서 거절해요.',
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final paint in EselPaint.values)
                      ChoiceChip(
                        label: Text(EselPaints.of(paint).nameKo),
                        selected: color == paint,
                        onSelected: saving
                            ? null
                            : (_) => update(() => color = paint),
                      ),
                  ],
                ),
                if (error != null) Text(error!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialog, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: saving || color == null
                  ? null
                  : () async {
                      update(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await source.restore(date, color!);
                        if (dialog.mounted) Navigator.pop(dialog, true);
                      } catch (e) {
                        if (dialog.mounted) {
                          update(
                            () => error = e is Failure
                                ? e.message
                                : '복원하지 못했어요. 다시 시도해 주세요.',
                          );
                        }
                      } finally {
                        if (dialog.mounted) update(() => saving = false);
                      }
                    },
              child: Text(saving ? '저장 중…' : '복원하기'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('색 달력'),
      leading: IconButton(
        tooltip: '뒤로',
        onPressed: widget.onBack,
        icon: const Icon(Icons.arrow_back_ios_new),
      ),
      actions: [
        IconButton(
          tooltip: '새로고침',
          onPressed: _busy ? null : () => _load(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '이전 달',
                onPressed: _busy ? null : () => _load(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _records?.month ?? '색 기록',
                  textAlign: TextAlign.center,
                  style: EselTypography.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: '다음 달',
                onPressed:
                    _busy ||
                        _month == null ||
                        (_month!.year == _today?.year &&
                            _month!.month == _today?.month)
                    ? null
                    : () => _load(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: () => _load(), child: const Text('다시 시도')),
          ],
          if (_records case final records?) ...[
            Text('${records.month} 남은 복원 ${records.remaining}회'),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(box.maxWidth, 7 * 48),
                  child: Wrap(
                    children: [
                      for (
                        var day = 1;
                        day <=
                            DateTime.utc(
                              _month!.year,
                              _month!.month + 1,
                              0,
                            ).day;
                        day++
                      )
                        SizedBox(
                          width: math.max(box.maxWidth / 7, 48),
                          child: _day(day),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('사진 기록은 표지를, 테두리 링은 나만 보는 복원 기록을 뜻해요.'),
          ],
        ],
      ),
    ),
  );
  Widget _day(int day) {
    final date = ServiceDate(_month!.year, _month!.month, day);
    final found = _records!.days.where((v) => v.date == date).firstOrNull;
    final canRestore =
        found == null &&
        _records!.remaining > 0 &&
        date.isBefore(_today!) &&
        date.year == _today!.year &&
        date.month == _today!.month;
    return TextButton(
      onPressed: found?.issueId != null
          ? () => widget.onOpenIssue(found!.issueId!)
          : canRestore
          ? () => _restore(date)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$day'),
          if (found != null)
            found.restored
                ? const Icon(Icons.radio_button_unchecked, size: 20)
                : EselPaintAsset(paint: found.color, width: 20)
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }
}
