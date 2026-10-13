import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/exam_prep_data.dart';
import 'package:kanken/data/kanken_data_parts.dart';
import 'package:kanken/models/kanji_question.dart' as k;
import 'package:kanken/viewmodels/practice_viewmodel.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart';
import 'package:kanken/views/core_features_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

/// 履歴を固定して始める（保存先は通常どおり端末内のモック）。
class _SeededHistory extends HistoryNotifier {
  _SeededHistory(this.seed);
  final List<ProgressRecord> seed;

  @override
  List<ProgressRecord> build() {
    super.build();
    return seed;
  }
}

ProgressRecord _rec(String qid, bool ok, DateTime at) => ProgressRecord(
    qid: qid, subjectId: 'kanji', topicId: 'LEVEL_10', correct: ok, at: at);

k.KanjiQuestion _kq(String id, String kanji, String reading) => k.KanjiQuestion(
      id: id,
      level: 'LEVEL_10',
      kanji: kanji,
      questionType: k.QuestionType.multipleChoice,
      choices: [kanji, '二', '三', '四'],
      correctAnswer: kanji,
      version: 1,
      reading: reading,
    );

List<Override> _overrides(List<ProgressRecord> history, {DateTime? exam}) => [
      historyProvider.overrideWith(() => _SeededHistory(history)),
      currentUserProvider.overrideWith((ref) async => null),
      examPrepExamDateProvider.overrideWithValue(exam),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 14, 12); // 水曜日

  group('推しの一言', () {
    test('入力は履歴・連続日数・試験日から作る', () {
      final c = oshiMessageContextFrom(
        history: [
          _rec('a', true, DateTime(2026, 10, 14, 9)),
          _rec('b', false, DateTime(2026, 10, 14, 10)),
          _rec('c', true, DateTime(2026, 10, 14, 11)),
        ],
        now: now,
        streakDays: 4,
        examDate: DateTime(2026, 11, 14),
      );
      expect(c.daysSinceLastStudy, 0);
      expect(c.streakDays, 4);
      expect(c.todayAnswered, 3);
      expect(c.todayCorrectRate, closeTo(2 / 3, 1e-9));
      expect(c.examDaysLeft, 31);
      expect(c.hasWeakTopics, isTrue);
    });

    test('履歴なし・試験日なし・過去の試験日は穏やかな既定値', () {
      final c = oshiMessageContextFrom(
          history: const [], now: now, examDate: DateTime(2026, 10, 1));
      expect(c.daysSinceLastStudy, isNull);
      expect(c.todayAnswered, 0);
      expect(c.todayCorrectRate, isNull);
      expect(c.examDaysLeft, isNull);
      expect(c.hasWeakTopics, isFalse);
    });

    test('最終学習日は履歴とユーザー情報の新しい方', () {
      final c = oshiMessageContextFrom(
        history: [_rec('a', true, DateTime(2026, 10, 5))],
        now: now,
        lastStudyDate: DateTime(2026, 10, 9),
      );
      expect(c.daysSinceLastStudy, 5);
    });

    testWidgets('履歴なしでもあいさつが表示される', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: _overrides(const []),
        child: MaterialApp(
            home: Scaffold(body: OshiMessageEntry(clock: () => now))),
      ));
      await tester.pump();
      expect(find.byType(OshiMessageBubble), findsOneWidget);
      final texts = OshiMessageStrings.ja.variants(OshiSituation.greeting);
      expect(texts.any((t) => find.text(t).evaluate().isNotEmpty), isTrue);
    });

    testWidgets('久しぶりの履歴なら、責めない「おかえり」系の一言', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: _overrides([_rec('a', true, DateTime(2026, 10, 5))]),
        child: MaterialApp(
            home: Scaffold(body: OshiMessageEntry(clock: () => now))),
      ));
      await tester.pump();
      final texts = OshiMessageStrings.ja.variants(OshiSituation.welcomeBack);
      expect(texts.any((t) => find.text(t).evaluate().isNotEmpty), isTrue);
    });
  });

  group('週間ふりかえり', () {
    final s = WeeklyRecapStrings.ja;

    testWidgets('今週の履歴があれば解いた数と学習した日を表示', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: _overrides([
          _rec('a', true, DateTime(2026, 10, 12, 9)), // 月曜
          _rec('b', false, DateTime(2026, 10, 12, 9, 5)),
          _rec('c', true, DateTime(2026, 10, 13, 9)),
        ]),
        child: MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: WeeklyRecapEntry(clock: () => now)))),
      ));
      await tester.pump();
      expect(find.byType(WeeklyRecapCard), findsOneWidget);
      expect(find.text('3${s.questionsUnit}'), findsOneWidget);
      expect(find.text('2${s.daysUnit}'), findsWidgets);
      expect(find.text(s.emptyTitle), findsNothing);
    });

    testWidgets('履歴なし・今週0件(先週のみ)は穏やかな「ひと休み」表示', (tester) async {
      for (final history in [
        <ProgressRecord>[],
        [_rec('a', true, DateTime(2026, 10, 7, 9))], // 前の週
      ]) {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(ProviderScope(
          key: UniqueKey(),
          overrides: _overrides(history),
          child: MaterialApp(
              home: Scaffold(body: WeeklyRecapEntry(clock: () => now))),
        ));
        await tester.pump();
        expect(find.text(s.emptyTitle), findsOneWidget);
      }
    });
  });

  group('間違いノート', () {
    final prevHistory = [
      _rec('q1', false, DateTime.now().subtract(const Duration(hours: 2))),
      _rec('q2', false, DateTime.now().subtract(const Duration(hours: 1))),
    ];

    Future<k.KanjiQuestion?> loader(String id) async =>
        id == 'q1' ? _kq('q1', '一', 'いち') : null; // q2 は取得できない

    Future<List<k.KanjiQuestion>> pool(String level) async => [
          _kq('q1', '一', 'いち'),
          _kq('x2', '二', 'に'),
          _kq('x3', '三', 'さん'),
          _kq('x4', '四', 'よん'),
        ];

    testWidgets('間違えた問題が載り、取得できない問題は省略される', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: _overrides(prevHistory),
        child: MaterialApp(
            home: MistakeNoteScreen(loadQuestion: loader, loadPool: pool)),
      ));
      await tester.pumpAndSettle();
      expect(find.text('一（いち）'), findsOneWidget);
      expect(find.text(MistakeNoteStrings.ja.retry), findsOneWidget);
      // 履歴の取り込み結果は端末内に保存される
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ukalab_kanken_mistake_notes'), contains('q1'));
    });

    testWidgets('履歴が無ければ穏やかな空の表示', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: _overrides(const []),
        child: MaterialApp(
            home: MistakeNoteScreen(loadQuestion: loader, loadPool: pool)),
      ));
      await tester.pumpAndSettle();
      expect(find.text(MistakeNoteStrings.ja.emptyUpcomingTitle), findsOneWidget);
      expect(find.text(MistakeNoteStrings.ja.retry), findsNothing);
    });

    testWidgets('解き直すと既存の出題画面が、その1問だけで開く', (tester) async {
      SharedPreferences.setMockInitialValues({});
      late ProviderContainer container;
      await tester.pumpWidget(ProviderScope(
        overrides: _overrides(prevHistory),
        child: Consumer(builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(
            home: MistakeNoteScreen(
              loadQuestion: loader,
              loadPool: pool,
              practiceBuilder: (_) => const Scaffold(body: Text('PRACTICE')),
            ),
          );
        }),
      ));
      await tester.pumpAndSettle();
      container.read(currentLevelProvider.notifier).state = 'LEVEL_9';

      await tester.tap(find.text(MistakeNoteStrings.ja.retry));
      await tester.pumpAndSettle();
      expect(find.text('PRACTICE'), findsOneWidget);
      final retry = container.read(practiceRetryQuestionsProvider);
      expect(retry, hasLength(1));
      expect(retry!.single.source.id, 'q1');
      expect(retry.single.choices, contains(retry.single.correctAnswer));
      expect(container.read(currentLevelProvider), 'LEVEL_10');
      final qs = await container.read(practiceQuestionsProvider('LEVEL_10').future);
      expect(qs.single.source.id, 'q1');

      // 戻ると、通常の出題設定と級に戻る
      Navigator.of(tester.element(find.text('PRACTICE'))).pop();
      await tester.pumpAndSettle();
      expect(container.read(practiceRetryQuestionsProvider), isNull);
      expect(container.read(currentLevelProvider), 'LEVEL_9');
    });
  });

  testWidgets('バックアップ・リセットに間違いノートが登録されている', (tester) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef wref;
    await tester.pumpWidget(ProviderScope(
      child: Consumer(builder: (context, ref, _) {
        wref = ref;
        return const SizedBox();
      }),
    ));
    final part = kankenDataParts.firstWhere((p) => p.id == 'mistakeNotes');
    final entry = MistakeNoteEngine()
        .build([_rec('q1', false, DateTime(2026, 10, 12, 9))]).single;
    await tester.runAsync(() async {
      await kankenMistakeNoteStore.write([entry]);
      final exported = await part.export(wref);
      expect(exported, isA<List>());
      expect((exported as List).single['qid'], 'q1');

      await part.reset(wref);
      expect(await kankenMistakeNoteStore.read(), isEmpty);

      await part.restore(wref, exported);
      expect((await kankenMistakeNoteStore.read()).single.qid, 'q1');
    });
  });
}
