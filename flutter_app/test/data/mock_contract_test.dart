import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/feed/data/sources/feed_mock_source.dart';
import 'package:esel/features/feed/data/sources/feed_remote_source.dart';
import 'package:esel/features/feed/domain/models/feed_page.dart';
import 'package:esel/features/magazine/data/sources/magazine_mock_source.dart';
import 'package:esel/features/stand/data/sources/stand_mock_source.dart';
import 'package:esel/features/stand/data/sources/stand_remote_source.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';
import 'package:esel/features/today/domain/rules/daily_candidates.dart';

void main() {
  // 디자인 시안의 날: 후보 카멜·라일락·올리브, 앱 표지 Nº 249.
  const today = DailyCandidates.demoDate;
  final candidates = DailyCandidates.forDate(today);
  final before = SameColorViewer(
    today: today,
    candidates: candidates,
    hasPublishedToday: false,
    isMinor: false,
  );
  final after = SameColorViewer(
    today: today,
    candidates: candidates,
    hasPublishedToday: true,
    isMinor: false,
  );

  group('DEV-03 mock 피드', () {
    final feed = FeedMockSource();

    test('비로그인은 오늘의 표지와 안쪽 2쪽까지만 받는다(P12)', () async {
      final page = await feed.today(
        viewer: const SameColorViewer.reader(today),
        signedIn: false,
      );
      expect(page.cover!.masthead, 'dana');
      expect(page.innerPages.map((i) => i.masthead), ['ama', 'lise']);
      expect(page.pagesForMembers, greaterThan(0));
      expect(page.appIssueNumber, 249);
      expect(page.sameColorCount(EselPaint.powder), 3);
    });

    test('올리기 전에는 잠긴 후보 색 표지가 피드로 새지 않는다(P01)', () async {
      final page = await feed.today(viewer: before, signedIn: true);
      expect(page.heldBack, isTrue);
      expect(page.issues.where((i) => candidates.contains(i.color)), isEmpty);
      expect(page.pagesForMembers, 0);

      final open = await feed.today(viewer: after, signedIn: true);
      expect(open.heldBack, isFalse);
      expect(
        open.issues.where((i) => i.color == EselPaint.camel),
        hasLength(4),
      );
    });

    test('구독 탭은 구독한 잡지만', () async {
      final page = await feed.today(
        viewer: after,
        signedIn: true,
        tab: FeedTab.subscribed,
        subscribedOwnerIds: {'demo_kofi'},
      );
      expect(page.issues.map((i) => i.masthead), ['kofi']);
      final none = await feed.today(
        viewer: after,
        signedIn: true,
        tab: FeedTab.subscribed,
      );
      expect(none.issues, isEmpty);
    });
  });

  group('DEV-03 mock 팔레트', () {
    final stand = StandMockSource();

    test('잠긴 방은 최신 3장과 개수만, 숨긴 표지의 이름은 오지 않는다', () async {
      final shelf = await stand.shelf(viewer: before, color: EselPaint.camel);
      expect(shelf.isPreview, isTrue);
      expect(shelf.items.map((i) => i.masthead), ['mara', 'selin', 'noor']);
      expect(shelf.hiddenCount, 1);
      expect(shelf.total, 4);

      final open = await stand.shelf(viewer: after, color: EselPaint.camel);
      expect(open.isPreview, isFalse);
      expect(open.items.map((i) => i.masthead), contains('leo'));
    });

    test('같은 색 인원', () async {
      expect(await stand.sameColorCount(today, EselPaint.camel), 4);
    });
  });

  group('DEV-03 mock 스케치북', () {
    final magazines = MagazineMockSource();

    test('누른 사람의 스케치북이 열리고 호수는 결호 없이 내려간다(P04)', () async {
      final lise = await magazines.magazine('demo_lise', viewer: after);
      expect(lise!.masthead, 'lise');
      expect(lise.isMine, isFalse);
      final numbers = lise.issues.map((i) => i.issueNumber).toList();
      expect(numbers.first, lise.totalIssues);
      for (var i = 1; i < numbers.length; i++) {
        expect(numbers[i], numbers[i - 1] - 1);
      }
      final kofi = await magazines.magazine('demo_kofi', viewer: after);
      expect(kofi!.masthead, 'kofi');
      expect(await magazines.magazine('nobody', viewer: after), isNull);
    });

    test('잠긴 오늘의 캔버스는 그 사람 스케치북에서도 보이지 않는다(P01)', () async {
      final selin = await magazines.magazine('demo_selin', viewer: before);
      expect(selin!.issues.first.date, isNot(today));
      expect(selin.todayColor, isNull);
      final opened = await magazines.magazine('demo_selin', viewer: after);
      expect(opened!.issues.first.date, today);
      expect(opened.todayColor, EselPaint.camel);
    });
  });

  test('서버 피드·팔레트 소스는 서버에 닿지 못해도 몰래 mock으로 바꾸지 않는다', () async {
    // 닫힌 포트: 곧바로 연결 실패.
    const config = AppConfig(
      apiMode: ApiMode.server,
      apiBaseUrl: 'http://127.0.0.1:1/api',
    );
    final http = StandardHttpClient(
      config: config,
      storage: InMemorySessionStorage(),
    );
    await expectLater(
      FeedRemoteSource(http).today(viewer: before, signedIn: true),
      throwsA(isA<NetworkFailure>()),
    );
    await expectLater(
      StandRemoteSource(http).shelf(viewer: before),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('공개 응답 모델에는 반응 숫자 필드가 없다(P18)', () {
    for (final path in [
      'lib/features/issue/domain/models/public_issue.dart',
      'lib/features/feed/domain/models/feed_page.dart',
      'lib/features/stand/domain/models/stand_shelf.dart',
      'lib/features/magazine/domain/models/magazine_models.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        isNot(
          matches(
            RegExp(
              r'(like|subscriber|scrap|readerLine|read)Count',
              caseSensitive: false,
            ),
          ),
        ),
        reason: path,
      );
    }
  });

  test('ServiceDate는 서비스 날짜 하나로 비교한다', () {
    expect(today, const ServiceDate(2026, 9, 6));
  });
}
