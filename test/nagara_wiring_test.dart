import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/exam_prep_data.dart' show historyProvider;
import 'package:kanken/models/kanji_question.dart' as k;
import 'package:kanken/screens/nagara_session_screen.dart';
import 'package:kanken/screens/settings_screen.dart' show HandsFreeSection;
import 'package:kanken/viewmodels/practice_viewmodel.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ながら学習（app_common_kit v3.1.0 の NagaraSessionView）と漢検アプリの連携テスト。
PracticeQuestion _q(int i) {
  final kanji = '漢$i';
  final choices = ['よみ$i', 'ほか$i', 'べつ$i'];
  return PracticeQuestion(
    source: k.KanjiQuestion(
      id: 'q$i',
      level: 'LEVEL_10',
      kanji: kanji,
      questionType: k.QuestionType.multipleChoice,
      choices: choices,
      correctAnswer: choices.first,
      version: 1,
      reading: 'よみ$i',
    ),
    actualMode: PracticeMode.reading,
    prompt: kanji,
    instruction: 'この漢字の読み方はどれ？',
    choices: choices,
    correctAnswer: choices.first,
  );
}

({ProviderContainer container, FakeSpeechBackend speech}) _setup({int count = 12}) {
  SharedPreferences.setMockInitialValues({});
  final speech = FakeSpeechBackend();
  final container = ProviderContainer(overrides: [
    handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
    speechBackendProvider.overrideWithValue(speech),
    currentUserProvider.overrideWith((ref) async => null),
    currentUserIdProvider.overrideWith((ref) => null),
    nagaraQuestionsProvider.overrideWith((ref, level) async => [for (var i = 1; i <= count; i++) _q(i)]),
  ]);
  addTearDown(container.dispose);
  return (container: container, speech: speech);
}

Widget _app(ProviderContainer c, Widget home) =>
    UncontrolledProviderScope(container: c, child: MaterialApp(home: home));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 10));
  await tester.pump();
}

void main() {
  testWidgets('入口: 学習メニューの「ながら学習」から開き、問題を読み上げる', (tester) async {
    final s = _setup();
    await tester.pumpWidget(_app(
      s.container,
      const Scaffold(body: SizedBox(width: 200, height: 200, child: NagaraMenuCard())),
    ));
    await tester.tap(find.byType(NagaraMenuCard));
    await _settle(tester);
    await _settle(tester);

    expect(find.byType(NagaraSessionView), findsOneWidget);
    expect(s.speech.spoken, isNotEmpty);
    expect(s.speech.spoken.first, contains('漢'));

    // 画面を離れて後片付け（タイマー・読み上げを止める）
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('誤答は履歴（間違いノートの元）に載る。正解は載らない', (tester) async {
    final s = _setup();
    await tester.pumpWidget(_app(s.container, const NagaraSessionScreen()));
    await _settle(tester);
    await _settle(tester);

    // 問題の並びは毎回違うので、表示中の問題の正解/不正解の選択肢を探す。
    final prompt = find.textContaining('漢').evaluate().isNotEmpty;
    expect(prompt, isTrue);
    final wrong = find.textContaining('ほか');
    expect(wrong, findsOneWidget);
    await tester.tap(wrong);
    await _settle(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));

    final history = s.container.read(historyProvider);
    expect(history.where((r) => !r.correct).length, 1);
    expect(history.single.subjectId, 'kanji');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('終了を押すと止まり、それ以上読み上げない', (tester) async {
    final s = _setup();
    await tester.pumpWidget(_app(s.container, const NagaraSessionScreen()));
    await _settle(tester);
    await _settle(tester);
    await tester.tap(find.text('終了'));
    await _settle(tester);
    final count = s.speech.spoken.length;
    await tester.pump(const Duration(seconds: 60));
    expect(s.speech.spoken.length, count);
    expect(find.text('おつかれさまでした'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('10問で「がんばったね。ひと休みしよう」と声をかける（責めない）', (tester) async {
    final s = _setup();
    await tester.pumpWidget(_app(s.container, const NagaraSessionScreen()));
    await _settle(tester);
    await _settle(tester);
    for (var i = 0; i < nagaraSessionSize; i++) {
      await tester.tap(find.text('スキップ'));
      await _settle(tester);
      await _settle(tester);
    }
    expect(find.text('がんばったね。ひと休みしよう'), findsOneWidget);
    expect(find.text('とじる'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('設定: 考える間・次までの間・自動で次へを変えると保存され、画面に反映される', (tester) async {
    final s = _setup();
    await tester.pumpWidget(_app(s.container, const Scaffold(body: SingleChildScrollView(child: HandsFreeSection()))));
    await tester.pump();

    expect(find.text('考える時間'), findsOneWidget);
    expect(find.text('次の問題までの間'), findsOneWidget);

    await s.container.read(handsFreeProvider.notifier).setThinkSeconds(12);
    await s.container.read(handsFreeProvider.notifier).setBetweenSeconds(5);
    await tester.pump();
    expect(find.text(NagaraStrings.ja.secondsOption(12)), findsWidgets);
    expect(find.text(NagaraStrings.ja.secondsOption(5)), findsWidgets);

    await tester.tap(find.byType(SwitchListTile).last);
    await tester.pump();
    final saved = s.container.read(handsFreeProvider);
    expect(saved.autoAdvance, isFalse);
    expect(saved.thinkSeconds, 12);

    // 保存された設定が復元できる
    final store = InMemoryHandsFreeStore();
    final a = ProviderContainer(overrides: [handsFreeStoreProvider.overrideWithValue(store)]);
    addTearDown(a.dispose);
    await a.read(handsFreeProvider.notifier).update(saved);
    final b = ProviderContainer(overrides: [handsFreeStoreProvider.overrideWithValue(store)]);
    addTearDown(b.dispose);
    await b.read(handsFreeProvider.notifier).load();
    expect(b.read(handsFreeProvider).betweenSeconds, 5);
  });

  test('出題は選択式の読み・書き取りだけで、10問まで', () {
    final all = [
      for (var i = 1; i <= 15; i++) _q(i).source,
      k.KanjiQuestion(
        id: 'hw',
        level: 'LEVEL_10',
        kanji: '手',
        questionType: k.QuestionType.handwriting,
        choices: const [],
        correctAnswer: '手',
        version: 1,
        reading: 'て',
      ),
    ];
    final built = buildNagaraPracticeQuestions(all, 'LEVEL_TEST'); // 配当漢字表が無い級は絞り込まない
    expect(built.length, nagaraSessionSize);
    expect(built.any((q) => q.source.id == 'hw'), isFalse);
    expect(
      built.every((q) => q.actualMode == PracticeMode.reading || q.actualMode == PracticeMode.writing),
      isTrue,
    );
    for (final q in built) {
      expect(toNagaraQuestion(q).correctIndex, greaterThanOrEqualTo(0));
    }
  });
}
