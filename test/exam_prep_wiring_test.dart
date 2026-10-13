import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/exam_prep_data.dart';
import 'package:kanken/data/kanken_data_parts.dart';
import 'package:kanken/models/kanji_question.dart' as k;
import 'package:kanken/views/exam_prep_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

k.KanjiQuestion _kq(String id, String kanji, String reading) => k.KanjiQuestion(
      id: id,
      level: 'LEVEL_10',
      kanji: kanji,
      questionType: k.QuestionType.multipleChoice,
      choices: const [],
      correctAnswer: kanji,
      version: 1,
      reading: reading,
    );

Question _q(String qid) => Question(
      qid: qid,
      examId: kExamId,
      subjectId: 'kanji',
      topicId: 'LEVEL_10',
      prompt: '問題$qid',
      choices: const ['A', 'B'],
      answerIndex: 0,
      explanation: '解説',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('更新ログ・チェックリストの同梱データが読め、チェックリストは全項目が公式要確認', () async {
    final log = await loadUpdateLog(now: DateTime(2026, 10, 13));
    expect(log, isNotEmpty);
    for (var i = 1; i < log.length; i++) {
      expect(log[i - 1].date.isBefore(log[i].date), isFalse);
    }
    final items = await loadChecklist();
    expect(items.length, greaterThanOrEqualTo(5));
    expect(unconfirmedItems(items).length, items.length);
    expect(items.every((i) => i.examId == kExamId), isTrue);
    // 断定しない: 全項目に公式確認の注記があり、「必ず」等の断定語を含まない
    for (final i in items) {
      expect(i.note, isNotNull);
      expect('${i.label}${i.note}'.contains('必ず'), isFalse);
    }
  });

  test('漢字の問題を core の Question にできる(読みが無い・選択肢不足は対象外)', () {
    final src = [
      _kq('a', '一', 'いち'),
      _kq('b', '二', 'に'),
      _kq('c', '三', 'さん'),
      _kq('d', '四', 'よん'),
      k.KanjiQuestion(
          id: 'e',
          level: 'LEVEL_10',
          kanji: '五',
          questionType: k.QuestionType.multipleChoice,
          choices: const [],
          correctAnswer: '五',
          version: 1),
    ];
    final qs = examPrepQuestions(src);
    expect(qs.map((q) => q.qid), ['a', 'b', 'c', 'd']);
    for (final q in qs) {
      expect(q.choices.length, 4);
      expect(q.choices[q.answerIndex], isNotEmpty);
    }
    expect(qs.first.choices[qs.first.answerIndex], 'いち');
    expect(examPrepQuestions([_kq('a', '一', 'いち')]), isEmpty);
  });

  test('premium 制限は core の PremiumFeature ルールに従う', () {
    expect(canUsePremiumFeature(PremiumFeature.tenMinutePlan, isPremium: false),
        isFalse);
    expect(canUsePremiumFeature(PremiumFeature.historyExport, isPremium: true),
        isTrue);
  });

  test('履歴CSVに個人情報・問題IDを含めない', () {
    final csv = historyCsvText([
      ProgressRecord(
          qid: 'secret-id',
          subjectId: 'kanji',
          topicId: 'LEVEL_10',
          at: DateTime(2026, 10, 12, 9),
          correct: true),
    ], [
      _q('secret-id')
    ]);
    expect(csv, contains('日付,解答数,正答数,正答率(%),学習時間(分)'));
    expect(csv, isNot(contains('secret')));
  });

  test('履歴は端末内に保存され、再読み込みで戻る', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(historyProvider.notifier).recordAnswer(
        questionId: 'a',
        level: 'LEVEL_10',
        correct: false,
        at: DateTime(2026, 10, 12));
    expect(c.read(historyProvider), hasLength(1));
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    c2.read(historyProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c2.read(historyProvider), hasLength(1));
    expect(c2.read(historyProvider).first.correct, isFalse);
  });

  testWidgets('チェックリスト: チェックが保存され、バックアップ対象に入る', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final items = [
      for (final id in ['a', 'b'])
        ChecklistItem(
            itemId: id,
            examId: kExamId,
            category: ChecklistCategory.belongings,
            label: '項目$id'),
    ];
    late WidgetRef wref;
    await tester.pumpWidget(ProviderScope(
      child: Consumer(builder: (context, ref, _) {
        wref = ref;
        return MaterialApp(
            home: ExamDayChecklistView(
          examId: kExamId,
          items: items,
          initialProgress: ref.read(checklistProvider),
          onChanged: ref.read(checklistProvider.notifier).setProgress,
        ));
      }),
    ));
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('ukalab_kanken_exam_checklist_v1'), hasLength(1));
    final part = kankenDataParts.firstWhere((p) => p.id == 'examChecklist');
    expect(part.export(wref), hasLength(1));
    await tester.runAsync(() => part.reset(wref));
    expect(wref.read(checklistProvider).checkedIds, isEmpty);
    await tester.runAsync(() => part.restore(wref, ['a', 'b']));
    expect(wref.read(checklistProvider).checkedIds, {'a', 'b'});
  });

  testWidgets('更新ログ: 表示し、空なら穏やかな文言', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: UpdateLogView(
          entriesFuture: Future.value([
        UpdateLogEntry(
            entryId: 'a',
            examId: kExamId,
            date: DateTime(2026, 10, 10),
            kind: UpdateKind.newContent,
            title: '追加しました'),
      ])),
    ));
    await tester.pump();
    expect(find.text('追加しました'), findsOneWidget);
    await tester.pumpWidget(
        MaterialApp(home: UpdateLogView(entriesFuture: Future.value([]))));
    await tester.pump();
    expect(find.text(ExamPrepStrings.ja.updateLogEmpty), findsOneWidget);
  });

  testWidgets('ホームのカード: 試験日が近いときだけ試験直前・チェックリストが出る', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 10, 13);
    Future<void> pump(DateTime? exam) async {
      await tester.pumpWidget(ProviderScope(
        key: UniqueKey(),
        overrides: [
          examPrepExamDateProvider.overrideWithValue(exam),
          examPrepQuestionsProvider.overrideWith((ref) async => [_q('a')]),
        ],
        child: MaterialApp(
            home: Scaffold(body: ExamPrepEntryCard(clock: () => now))),
      ));
      await tester.pump();
    }

    await pump(null);
    expect(find.byKey(const ValueKey('tenMinPlanTile')), findsOneWidget);
    expect(find.byKey(const ValueKey('examEveTile')), findsNothing);

    await pump(DateTime(2026, 10, 15));
    expect(find.byKey(const ValueKey('examEveTile')), findsOneWidget);
    expect(find.byKey(const ValueKey('checklistTile')), findsOneWidget);
  });

  testWidgets('練習: 解答すると履歴に1件残る', (tester) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef wref;
    await tester.pumpWidget(ProviderScope(
      child: Consumer(builder: (context, ref, _) {
        wref = ref;
        return MaterialApp(
            home: Scaffold(
                body: ExamPrepPracticeView(pool: [_q('a')], emptyMessage: '空')));
      }),
    ));
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(find.text('せいかい！'), findsOneWidget);
    expect(wref.read(historyProvider), hasLength(1));
  });
}
