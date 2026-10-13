import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanken/models/category_label.dart';
import 'package:kanken/providers/achievement_provider.dart';
import 'package:kanken/providers/oshi_provider.dart';
import 'package:kanken/providers/ranking_provider.dart';
import 'package:kanken/providers/spaced_repetition_provider.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart';
import 'package:kanken/views/core_v069_entry.dart';
import 'package:kanken/views/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

final _now = DateTime(2026, 10, 13, 12);

ReviewItem _item(String qid, {int stage = 0, DateTime? due}) => ReviewItem(
      qid: qid,
      stage: stage,
      dueAt: due ?? DateTime(2026, 10, 12),
      lastReviewedAt: DateTime(2026, 10, 11),
      topicId: 'LEVEL_5',
    );

Widget _app({
  List<ReviewItem> review = const [],
  OshiGrowthService? growth,
}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
  ]);
  return ProviderScope(
    overrides: [
      coinServiceProvider
          .overrideWithValue(CoinService(store: InMemoryCoinStore())),
      outfitServiceProvider
          .overrideWithValue(OutfitService(store: InMemoryOutfitStore())),
      oshiStageProvider.overrideWith((ref) async => MascotStage.lv1),
      userAchievementsProvider.overrideWith((ref) async => []),
      currentUserIdProvider.overrideWith((ref) => null),
      currentUserProvider.overrideWith((ref) async => null),
      reviewReminderCheckProvider.overrideWith((ref) async {}),
      rankingProvider.overrideWith((ref, filter) async => []),
      practiceQuestionsProvider.overrideWith((ref, level) async => []),
      reviewScheduleProvider.overrideWith((ref) async => review),
      oshiGrowthServiceProvider.overrideWithValue(
          growth ?? OshiGrowthService(store: InMemoryOshiGrowthStore())),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pump(WidgetTester t, Widget w,
    {double width = 400, double textScale = 1.0}) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = Size(width, 900);
  t.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
    t.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await t.pumpWidget(w);
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
}

Future<void> _show(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await t.pump();
}

/// 解答履歴を端末内に入れておく（HistoryNotifier が起動時に読む）。
void _seedHistory(int answers, {int days = 1}) {
  final records = [
    for (var i = 0; i < answers; i++)
      ProgressRecord(
        qid: 'q$i',
        subjectId: 'kanji',
        topicId: 'LEVEL_5',
        correct: true,
        at: DateTime.now().subtract(Duration(days: i % days)),
      ),
  ];
  SharedPreferences.setMockInitialValues(
      {'ukalab_kanken_history_v1': encodeHistory(records)});
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ホーム', () {
    testWidgets('今日やることに今日の復習カードが出る（0件は静かな表示）', (t) async {
      await _pump(t, _app());
      final title = find.text(ReviewSchedulerStrings.ja.title);
      await _show(t, title);
      expect(find.byType(TodayReviewCard), findsOneWidget);
      expect(find.text(ReviewSchedulerStrings.ja.emptyTitle), findsOneWidget);
      // 既存の入口はそのまま残る
      expect(find.text('復習（間隔反復）'), findsOneWidget);
      expect(find.text('演習を始める'), findsOneWidget);
    });

    testWidgets('期限の来た復習があれば件数とボタンが出る', (t) async {
      await _pump(t, _app(review: [_item('a'), _item('b')]));
      await _show(t, find.byType(TodayReviewCard));
      expect(find.text(ReviewSchedulerStrings.ja.dueText(2)), findsOneWidget);
      expect(find.text(ReviewSchedulerStrings.ja.start), findsOneWidget);
    });

    testWidgets('記録に推しの成長の一言が出る', (t) async {
      _seedHistory(12);
      await _pump(t, _app());
      await t.pump(const Duration(milliseconds: 300));
      // 10問に届いた祝福ダイアログを閉じる
      expect(find.byType(OshiGrowthCelebrationCard), findsOneWidget);
      Navigator.of(t.element(find.byType(OshiGrowthCelebrationCard))).pop();
      await t.pump(const Duration(milliseconds: 500));
      await _show(t, find.byType(OshiGrowthBubble));
      expect(find.byType(OshiGrowthBubble), findsOneWidget);
    });

    testWidgets('節目の祝福は一度だけ出る', (t) async {
      _seedHistory(12);
      final service = OshiGrowthService(store: InMemoryOshiGrowthStore());
      await _pump(t, _app(growth: service));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(OshiGrowthCelebrationCard), findsOneWidget);
      Navigator.of(t.element(find.byType(OshiGrowthCelebrationCard))).pop();
      await t.pump(const Duration(milliseconds: 500));
      expect(service.isCelebrated('answered_10'), isTrue);

      // 作り直しても、同じ節目はもう出ない
      await _pump(t, _app(growth: service));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(OshiGrowthCelebrationCard), findsNothing);
    });

    testWidgets('幅320・文字2倍でもオーバーフローしない', (t) async {
      _seedHistory(12);
      await _pump(t, _app(review: [_item('a')]),
          width: 320, textScale: 2.0);
      await t.pump(const Duration(milliseconds: 300));
      if (find.byType(OshiGrowthCelebrationCard).evaluate().isNotEmpty) {
        Navigator.of(t.element(find.byType(OshiGrowthCelebrationCard))).pop();
        await t.pump(const Duration(milliseconds: 500));
      }
      await _show(t, find.byType(TodayReviewCard));
      await _show(t, find.byType(OshiGrowthBubble));
      expect(t.takeException(), isNull);
    });
  });

  group('今日の復習', () {
    testWidgets('「やってみる」で onStart が呼ばれる', (t) async {
      var started = 0;
      await _pump(
        t,
        ProviderScope(
          overrides: [
            reviewScheduleProvider.overrideWith((ref) async => [_item('a')]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TodayReviewEntry(clock: () => _now, onStart: (_) => started++),
            ),
          ),
        ),
      );
      await t.tap(find.text(ReviewSchedulerStrings.ja.start));
      expect(started, 1);
    });

    test('期限が来ている問題だけ結果が反映される', () async {
      final store = InMemoryReviewSchedulerStore();
      await store.write([
        _item('due', stage: 1),
        _item('later', stage: 1, due: DateTime(2026, 10, 20)),
      ]);
      await recordReviewResult('due', correct: true, at: _now, store: store);
      await recordReviewResult('later', correct: true, at: _now, store: store);
      final items = {for (final i in await store.read()) i.qid: i};
      expect(items['due']!.stage, 2);
      expect(items['due']!.lastReviewedAt, _now);
      expect(items['later']!.stage, 1); // まだ期限前は動かさない
    });

    test('間違えると1段戻り、予定にない問題は何も起きない', () async {
      final store = InMemoryReviewSchedulerStore();
      await store.write([_item('a', stage: 2)]);
      await recordReviewResult('a', correct: false, at: _now, store: store);
      await recordReviewResult('zzz', correct: true, at: _now, store: store);
      final items = await store.read();
      expect(items.length, 1);
      expect(items.single.stage, 1);
    });
  });

  group('推しの成長', () {
    test('履歴から回答数と学習日数を数える', () {
      final p = oshiGrowthProgressFrom([
        for (var i = 0; i < 5; i++)
          ProgressRecord(
              qid: 'q$i',
              subjectId: 'kanji',
              correct: true,
              at: DateTime(2026, 10, 1 + i ~/ 3, 9 + i)),
      ]);
      expect(p.totalAnswered, 5);
      expect(p.studyDays, 2);
      expect(oshiGrowthProgressFrom(const []).totalAnswered, 0);
    });
  });

  group('模擬試験の結果分析', () {
    Widget host(List<MockExamAnswer> answers) => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MockExamAnalysisEntry(
                  answers: answers, topicLabel: categoryLabel),
            ),
          ),
        );

    List<MockExamAnswer> sample() => [
          for (var i = 0; i < 4; i++)
            MockExamAnswer(topicId: 'reading', correct: i < 3),
          for (var i = 0; i < 4; i++)
            MockExamAnswer(topicId: 'stroke', correct: i < 1),
        ];

    testWidgets('分野名は既存のラベル（読み・画数）で出る', (t) async {
      await _pump(t, host(sample()));
      expect(find.byType(MockExamAnalysisCard), findsOneWidget);
      expect(find.textContaining('画数'), findsWidgets);
      expect(find.text('stroke'), findsNothing);
    });

    testWidgets('解答がなければ何も出ない', (t) async {
      await _pump(t, host(const []));
      expect(find.byType(MockExamAnalysisCard), findsNothing);
    });

    testWidgets('幅320・文字2倍でもオーバーフローしない', (t) async {
      await _pump(t, host(sample()), width: 320, textScale: 2.0);
      expect(t.takeException(), isNull);
    });
  });
}
