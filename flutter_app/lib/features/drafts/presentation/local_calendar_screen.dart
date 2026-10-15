import 'package:flutter/material.dart';
import '../../../core/design/tokens.g.dart';
import '../data/local_library.dart';

class LocalCalendarScreen extends StatefulWidget {
  final LocalLibrary library;
  const LocalCalendarScreen({super.key, required this.library});
  @override
  State<LocalCalendarScreen> createState() => _LocalCalendarScreenState();
}

class _LocalCalendarScreenState extends State<LocalCalendarScreen> {
  late DateTime _month;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _move(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = _month.weekday % 7;
    return Scaffold(
      appBar: AppBar(title: const Text('초안 달력')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('초안을 마지막으로 편집한 날짜예요. 서버의 발행·복원 기록과는 별도로 보관돼요.'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: '이전 달',
                onPressed: () => _move(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${_month.year}년 ${_month.month}월'),
              IconButton(
                tooltip: '다음 달',
                onPressed:
                    _month.year == today.year && _month.month == today.month
                    ? null
                    : () => _move(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              '일',
              '월',
              '화',
              '수',
              '목',
              '금',
              '토',
            ].map((d) => Expanded(child: Center(child: Text(d)))).toList(),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 58,
            ),
            itemCount: offset + days,
            itemBuilder: (context, i) {
              if (i < offset) return const SizedBox.shrink();
              final date = DateTime(_month.year, _month.month, i - offset + 1);
              final drafts = widget.library.drafts
                  .where(
                    (d) =>
                        d.updatedAt.year == date.year &&
                        d.updatedAt.month == date.month &&
                        d.updatedAt.day == date.day,
                  )
                  .toList();
              return TextButton(
                onPressed: () => Navigator.pop(context, date),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${date.day}'),
                    if (drafts.isNotEmpty)
                      Container(
                        width: 12,
                        height: 5,
                        color: EselPaints.of(drafts.first.color).color,
                      ),
                  ],
                ),
              );
            },
          ),
          TextButton(
            onPressed: () =>
                setState(() => _month = DateTime(today.year, today.month)),
            child: const Text('이번 달로 돌아가기'),
          ),
        ],
      ),
    );
  }
}
