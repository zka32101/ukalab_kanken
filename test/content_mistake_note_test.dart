import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/content_mistake_store.dart';
import 'package:kanken/data/exam_prep_data.dart';
import 'package:kanken/data/kanken_data_parts.dart';
import 'package:kanken/models/kanji_question.dart' as k;
import 'package:kanken/viewmodels/practice_viewmodel.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart';
import 'package:kanken/views/core_features_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ukalab_core.dart' hide PracticeMode;

class _SeededHistory extends HistoryNotifier {
  _SeededHistory(this.seed);
  final List<ProgressRecord> seed;
  @override
  List<ProgressRecord> build() {
    super.build();
    return seed;
  }
}

ContentMistakeSnapshot _snap({String prompt = '有名無□', String answer = '実'}) {
  final id = contentQuestionId('yoji', prompt, answer);
  return ContentMistakeSnapshot(
    id: id,
    mode: 'yoji',
    level: 'LEVEL_5',
    prompt: prompt,
    instruction: '名前ばかりで、中身がともなわないこと。（ゆうめいむじつ）\n□に入る漢字はどれ？',
    choices: [answer, '日', '満', '態'],
    correctAnswer: answer,
    explanation: '正解: 有名無実（ゆうめいむじつ）',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('問題ID', () {
    test('内容から決まる・形式や問題文や正解が違えば別・接頭辞つき', () {
      final a = contentQuestionId('yoji', '有名無□', '実');
      expect(a, contentQuestionId('yoji', '有名無□', '実'));
      expect(a, startsWith(contentQuestionIdPrefix));
      expect(a, isNot(contentQuestionId('koji', '有名無□', '実')));
      expect(a, isNot(contentQuestionId('yoji', '有名□実', '無')));
      // 値は実行のたびに変わらない（保存された記録と突き合わせるため）
      expect(a, 'c:yoji:${a.split(':').last}');
      expect(a.split(':').last, hasLength(8));
    });
  });

  group('控えの保存', () {
    test('保存・読み出し・同じIDは入れ替え・壊れた入力は読み飛ばす', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await ContentMistakeStore.readAll(), isEmpty);
      final s = _snap();
      await ContentMistakeStore.save(s);
      await ContentMistakeStore.save(_snap(prompt: '虎視□□', answer: '眈'));
      await ContentMistakeStore.save(s); // 同じID: 最後へ
      final all = await ContentMistakeStore.readAll();
      expect(all.map((x) => x.id).toList(), [contentQuestionId('yoji', '虎視□□', '眈'), s.id]);
      expect((await ContentMistakeStore.read(s.id))!.explanation, s.explanation);
      expect(await ContentMistakeStore.read('c:yoji:zzzzzzzz'), isNull);

      SharedPreferences.setMockInitialValues({'ukalab_kanken_content_mistakes_v1': '[{"id":"x"},1,null]'});
      expect(await ContentMistakeStore.readAll(), isEmpty);
    });

    test('件数の上限を超えたら、古いものから捨てる', () async {
      SharedPreferences.setMockInitialValues({});
      for (var i = 0; i < ContentMistakeStore.maxItems + 5; i++) {
        await ContentMistakeStore.save(_snap(prompt: '問$i□', answer: '答'));
      }
      final all = await ContentMistakeStore.readAll();
      expect(all.length, ContentMistakeStore.maxItems);
      expect(all.first.prompt, '問5□');
      expect(all.last.prompt, '問${ContentMistakeStore.maxItems + 4}□');
    });
  });

  group('控えと問題', () {
    test('控えから解き直しの問題を作る（内容・正解・説明が同じで、同じIDになる）', () {
      final s = _snap();
      final q = practiceQuestionFromSnapshot(s, Random(1));
      expect(q.actualMode, PracticeMode.yoji);
      expect(q.prompt, s.prompt);
      expect(q.correctAnswer, s.correctAnswer);
      expect(q.choices.toSet(), s.choices.toSet());
      expect(q.explanation, s.explanation);
      expect(q.source.id, startsWith(contentQuestionIdPrefix));
      // 作り直した問題から、同じ控え・同じIDが得られる（解き直しの正解が、同じ記録に付く）
      expect(contentIdOf(q), s.id);
      expect(contentSnapshotOf(q, 'LEVEL_5').toJson()['id'], s.id);
    });
  });

  group('間違いノートの画面', () {
    final miss = DateTime.now().subtract(const Duration(hours: 1));
    List<Override> overrides(List<ProgressRecord> h) => [
          historyProvider.overrideWith(() => _SeededHistory(h)),
          currentUserProvider.overrideWith((ref) async => null),
          examPrepExamDateProvider.overrideWithValue(null),
        ];

    testWidgets('熟語系の間違いが載り、土台の漢字の問題は読み込まない', (tester) async {
      final s = _snap();
      SharedPreferences.setMockInitialValues({});
      await ContentMistakeStore.save(s);
      var loaded = <String>[];
      await tester.pumpWidget(ProviderScope(
        overrides: overrides([
          ProgressRecord(qid: s.id, subjectId: 'kanji', topicId: 'LEVEL_5', correct: false, at: miss),
        ]),
        child: MaterialApp(
          home: MistakeNoteScreen(
            loadQuestion: (id) async {
              loaded.add(id);
              return null;
            },
            loadPool: (level) async => <k.KanjiQuestion>[],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('四字熟語'), findsOneWidget);
      expect(find.text('有名無□'), findsOneWidget);
      expect(loaded, isEmpty);
    });

    testWidgets('控えが無い熟語系の記録は載せない（安全に省略）', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final id = contentQuestionId('yoji', '消えた□', '答');
      await tester.pumpWidget(ProviderScope(
        overrides: overrides([
          ProgressRecord(qid: id, subjectId: 'kanji', topicId: 'LEVEL_5', correct: false, at: miss),
        ]),
        child: MaterialApp(
          home: MistakeNoteScreen(
            loadQuestion: (id) async => null,
            loadPool: (level) async => <k.KanjiQuestion>[],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('消えた□'), findsNothing);
    });

    testWidgets('解き直すと、その問題だけで出題画面が開く', (tester) async {
      final s = _snap();
      SharedPreferences.setMockInitialValues({});
      await ContentMistakeStore.save(s);
      late ProviderContainer container;
      await tester.pumpWidget(ProviderScope(
        overrides: overrides([
          ProgressRecord(qid: s.id, subjectId: 'kanji', topicId: 'LEVEL_5', correct: false, at: miss),
        ]),
        child: Consumer(builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(
            home: MistakeNoteScreen(
              loadQuestion: (id) async => null,
              loadPool: (level) async => <k.KanjiQuestion>[],
              practiceBuilder: (_) => const Scaffold(body: Text('PRACTICE')),
            ),
          );
        }),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text(MistakeNoteStrings.ja.retry));
      await tester.pumpAndSettle();
      expect(find.text('PRACTICE'), findsOneWidget);
      final retry = container.read(practiceRetryQuestionsProvider);
      expect(retry, hasLength(1));
      expect(retry!.single.prompt, '有名無□');
      expect(retry.single.actualMode, PracticeMode.yoji);
      expect(retry.single.correctAnswer, '実');
      expect(container.read(currentLevelProvider), 'LEVEL_5');
    });
  });

  group('バックアップ・リセット', () {
    testWidgets('熟語系の控えが、書き出し・読み込み・リセットの対象に入っている', (tester) async {
      SharedPreferences.setMockInitialValues({});
      late WidgetRef wref;
      await tester.pumpWidget(ProviderScope(
        child: Consumer(builder: (context, ref, _) {
          wref = ref;
          return const SizedBox();
        }),
      ));
      final part = kankenDataParts.firstWhere((p) => p.id == 'contentMistakes');
      await tester.runAsync(() async {
        final s = _snap();
        await ContentMistakeStore.save(s);
        final exported = await part.export(wref);
        expect((exported as List).single['id'], s.id);

        await part.reset(wref);
        expect(await ContentMistakeStore.readAll(), isEmpty);

        // 壊れた項目は読み飛ばし、読めた分だけ戻る
        await part.restore(wref, [...exported, {'id': 'x'}, 1]);
        final back = await ContentMistakeStore.readAll();
        expect(back.single.id, s.id);
        expect(back.single.explanation, s.explanation);
      });
    });
  });
}
