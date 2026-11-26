import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/features/moderation/data/reports_source.dart';
import 'package:esel/features/moderation/domain/report.dart';
import 'package:esel/features/moderation/presentation/widgets/moderation_sheet.dart';
import 'package:esel/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/issue/data/demo_issue_catalog.dart';
import 'package:esel/features/issue/presentation/widgets/issue_bottom_sheet.dart';
import 'package:esel/features/reactions/presentation/controllers/reactions_controller.dart';
import '../server/core_api_widgets_test.dart' show ScreenHttp, useTestMedia;

/// DEV-20 신고: 캔버스를 사유와 함께 신고한다. 처리 기준은 미정이라 서버는 접수만 저장한다.
/// 전에는 신고 항목이 서버를 부르지 않으면서 "신고가 접수되었습니다. 검토 후 조치됩니다."라고 안내했다.
void main() {
  useTestMedia();

  test('서버 소스: POST /issues/:id/reports에 사유와 (있으면) 다듬은 내용을 보낸다', () async {
    final calls = <String>[];
    final http = ScreenHttp((method, path, body) async {
      calls.add('$method $path $body');
      return {
        'id': 'report-1',
        'status': 'RECEIVED',
        'createdAt': '2026-11-26T03:00:00.000Z',
      };
    });
    final source = ReportsRemoteSource(http);
    await source.reportIssue(
      'issue-1',
      ReportReason.spam,
      details: '  광고 링크  ',
    );
    await source.reportIssue('issue-1', ReportReason.other, details: '   ');
    expect(calls, [
      'POST /issues/issue-1/reports {reason: spam, details: 광고 링크}',
      'POST /issues/issue-1/reports {reason: other}',
    ]);
    expect(source.demo, isFalse);
    expect(ReportsMemorySource().demo, isTrue);
  });

  test('서버 사유 값과 실패 문구', () {
    expect(ReportReason.values.map((r) => r.apiValue), [
      'spam',
      'harassment',
      'inappropriate',
      'other',
    ]);
    expect(
      reportFailureMessage(
        const RuleFailure('요청이 너무 많아요.', code: 'RATE_LIMITED'),
      ),
      contains('1분 뒤'),
    );
    expect(
      reportFailureMessage(
        const NotFoundFailure('찾을 수 없어요.', code: 'NOT_FOUND'),
      ),
      contains('볼 수 없는 캔버스'),
    );
  });

  group('신고 시트', () {
    Future<List<bool>> open(
      WidgetTester tester,
      Future<String?> Function(ReportReason, String) onSubmit,
    ) async {
      final results = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => results.add(
                  await ReportSheet.show(
                    context,
                    authorMasthead: 'elin',
                    onSubmit: onSubmit,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('사유를 고르기 전에는 보낼 수 없고, 보내면 사유·내용을 넘기고 시트 안에서 접수를 알린다', (
      tester,
    ) async {
      final sent = <String>[];
      final results = await open(tester, (reason, details) async {
        sent.add('${reason.apiValue}|$details');
        return null;
      });

      await tester.tap(find.byKey(const Key('report-send')));
      await tester.pump();
      expect(sent, isEmpty);

      await tester.tap(find.byKey(const Key('report-reason-harassment')));
      await tester.enterText(find.byKey(const Key('report-details')), '반복 댓글');
      await tester.tap(find.byKey(const Key('report-send')));
      await tester.pumpAndSettle();

      expect(sent, ['harassment|반복 댓글']);
      // 결과는 시트 안에서 보인다(하단 알림은 자세히 보기 시트 뒤에 가려진다).
      expect(find.byKey(const Key('report-done')), findsOneWidget);
      expect(find.text('신고를 접수했어요.'), findsOneWidget);
      expect(results, isEmpty);
      await tester.tap(find.byKey(const Key('report-ok')));
      await tester.pumpAndSettle();
      expect(find.byType(ReportSheet), findsNothing);
      expect(results, [true]);
    });

    testWidgets('실패하면 이유를 보이고 열어 둔다. 보내는 중에는 다시 보낼 수 없다', (tester) async {
      var calls = 0;
      final pending = Completer<String?>();
      final results = await open(tester, (reason, details) {
        calls++;
        return pending.future;
      });
      await tester.tap(find.byKey(const Key('report-reason-spam')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('report-send')));
      await tester.pump();
      expect(find.text('보내는 중…'), findsOneWidget);
      await tester.tap(find.byKey(const Key('report-send')));
      await tester.pump();
      expect(calls, 1);

      pending.complete('신고가 너무 많아요. 1분 뒤 다시 시도해 주세요.');
      await tester.pumpAndSettle();
      expect(find.byType(ReportSheet), findsOneWidget);
      expect(find.byKey(const Key('report-error')), findsOneWidget);
      expect(find.text('신고 보내기'), findsOneWidget);
      expect(results, isEmpty);
    });
  });

  group('신고·차단 시트', () {
    Future<void> openSheet(
      WidgetTester tester, {
      VoidCallback? onReport,
      VoidCallback? onBlock,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => ModerationSheet.show(
                context,
                authorMasthead: 'elin',
                onReport: onReport,
                onBlock: onBlock,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('신고를 누르면 시트를 닫고 부른다. 접수됐다는 안내는 미리 띄우지 않는다', (tester) async {
      var reported = 0;
      await openSheet(tester, onReport: () => reported++, onBlock: () {});
      await tester.tap(find.byKey(const Key('moderation-report')));
      await tester.pumpAndSettle();
      expect(reported, 1);
      expect(find.textContaining('접수'), findsNothing);
    });

    testWidgets('신고할 수 없으면 신고 항목이 없다', (tester) async {
      await openSheet(tester, onBlock: () {});
      expect(find.byKey(const Key('moderation-report')), findsNothing);
      expect(find.byKey(const Key('moderation-block')), findsOneWidget);
    });
  });

  group('자세히 보기 ··· 버튼', () {
    Widget sheet({VoidCallback? onReport}) {
      final issue = DemoIssueCatalog.issuesOn(
        const ServiceDate(2026, 10, 17),
      ).first;
      return MaterialApp(
        home: Scaffold(
          body: IssueBottomSheet(
            issue: issue,
            isOwner: false,
            readerMasthead: 'viewer',
            reactionsController: ReactionsController(),
            onOpenAuthorShelf: () {},
            onShare: () {},
            onReport: onReport,
          ),
        ),
      );
    }

    testWidgets('신고·차단할 수 있으면 48×48 버튼, 내 캔버스처럼 없으면 버튼을 숨긴다', (tester) async {
      var opened = 0;
      await tester.pumpWidget(sheet(onReport: () => opened++));
      await tester.pumpAndSettle();
      final more = find.byKey(const Key('issue-more'));
      expect(more, findsOneWidget);
      expect(tester.getSize(more), const Size(48, 48));
      await tester.tap(more);
      expect(opened, 1);

      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('issue-more')), findsNothing);
    });
  });
}
