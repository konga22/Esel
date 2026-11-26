import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_button.dart';
import '../../domain/report.dart';

/// 표지 신고 시트(DEV-20). 사유를 하나 고르고(필수) 내용을 덧붙여(선택) 보낸다.
/// [onSubmit]이 성공하면(null) 시트 안에 [successMessage]와 확인 버튼을 보이고, 확인하면 `true`로 닫힌다.
/// 실패하면 이유를 보이며 열어 둔다.
///
/// 결과 안내를 하단 알림(SnackBar)으로 띄우지 않는 이유: 이 시트는 자세히 보기 시트 위에서 열려서,
/// 하단 알림은 자세히 보기 시트 뒤에 가려 보이지 않는다(2026-11-26 에뮬레이터에서 확인).
class ReportSheet extends StatefulWidget {
  final String authorMasthead;
  final Future<String?> Function(ReportReason reason, String details) onSubmit;
  final String successMessage;

  const ReportSheet({
    super.key,
    required this.authorMasthead,
    required this.onSubmit,
    this.successMessage = '신고를 접수했어요.',
  });

  /// 시트를 열고, 신고를 보냈으면 true를 돌려준다.
  static Future<bool> show(
    BuildContext context, {
    required String authorMasthead,
    required Future<String?> Function(ReportReason reason, String details)
    onSubmit,
    String successMessage = '신고를 접수했어요.',
  }) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportSheet(
        authorMasthead: authorMasthead,
        onSubmit: onSubmit,
        successMessage: successMessage,
      ),
    );
    return sent ?? false;
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;
  String? _error;
  bool _sending = false;
  bool _done = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await widget.onSubmit(reason, _details.text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (error == null) {
        _done = true;
      } else {
        _error = error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 사유 목록(RadioListTile)의 누름 효과가 보이도록 배경은 Container가 아니라 Material로 칠한다.
    return Material(
      color: EselTokens.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EselTokens.radius24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: EselTokens.space24,
          right: EselTokens.space24,
          top: EselTokens.space20,
          bottom: MediaQuery.of(context).viewInsets.bottom + EselTokens.space24,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: _done ? _buildDone(context) : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildDone(BuildContext context) => Column(
    key: const Key('report-done'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: EselTokens.space16),
      const Icon(Icons.check_circle_outline, size: 40, color: EselTokens.ink),
      const SizedBox(height: EselTokens.space16),
      Text(
        widget.successMessage,
        textAlign: TextAlign.center,
        style: EselTypography.headlineSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '신고한 사실은 상대에게 알리지 않아요.',
        textAlign: TextAlign.center,
        style: EselTypography.bodySmall.copyWith(color: EselTokens.inkMuted),
      ),
      const SizedBox(height: EselTokens.space24),
      EselButton(
        key: const Key('report-ok'),
        label: '확인',
        isPrimary: true,
        onTap: () => Navigator.of(context).pop(true),
      ),
    ],
  );

  Widget _buildForm() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${widget.authorMasthead} 님의 캔버스 신고',
        style: EselTypography.headlineSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '신고한 사실은 상대에게 알리지 않아요.',
        style: EselTypography.bodySmall.copyWith(color: EselTokens.inkMuted),
      ),
      const SizedBox(height: EselTokens.space16),
      RadioGroup<ReportReason>(
        groupValue: _reason,
        onChanged: (value) {
          if (_sending) return;
          setState(() {
            _reason = value;
            _error = null;
          });
        },
        child: Column(
          children: [
            for (final reason in ReportReason.values)
              RadioListTile<ReportReason>(
                key: Key('report-reason-${reason.apiValue}'),
                value: reason,
                enabled: !_sending,
                contentPadding: EdgeInsets.zero,
                title: Text(reason.label, style: EselTypography.bodyMedium),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        key: const Key('report-details'),
        controller: _details,
        enabled: !_sending,
        maxLength: reportDetailsMaxLength,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: '더 알려 줄 내용이 있으면 적어 주세요(선택)',
          filled: true,
          fillColor: EselTokens.paperWarm,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(EselTokens.radius14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 4),
        Text(
          _error!,
          key: const Key('report-error'),
          style: EselTypography.bodySmall.copyWith(
            color: EselTokens.semanticRed,
          ),
        ),
      ],
      const SizedBox(height: EselTokens.space16),
      EselButton(
        key: const Key('report-send'),
        label: _sending ? '보내는 중…' : '신고 보내기',
        isPrimary: true,
        enabled: _reason != null && !_sending,
        onTap: _send,
      ),
    ],
  );
}
