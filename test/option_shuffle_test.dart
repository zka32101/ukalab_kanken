import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/mock_exam_modes.dart';
import 'package:kanken/providers/exam_session_provider.dart';
import 'package:kanken/screens/mock_exam_enhanced_screen.dart';
import 'package:kanken/utils/option_shuffle.dart';

void main() {
  group('shuffledOptions', () {
    test('同じ問題IDなら何度呼んでも同じ順序(再描画で変わらない)', () {
      const opts = ['a', 'b', 'c', 'd'];
      final first = shuffledOptions('l9-reading-001', opts);
      for (var i = 0; i < 20; i++) {
        expect(shuffledOptions('l9-reading-001', opts), first);
      }
    });

    test('選択肢の中身は変わらず、元のリストも破壊しない', () {
      final opts = ['いち', 'に', 'さん', 'し'];
      final out = shuffledOptions('q-x', opts);
      expect(out.toSet(), opts.toSet());
      expect(out.length, opts.length);
      expect(opts, ['いち', 'に', 'さん', 'し']);
    });

    test('正解が常に先頭(A)に来ない: 120問ぶんのIDで位置が分散する', () {
      final counts = List<int>.filled(4, 0);
      for (final level in [9, 8, 7, 6, 5]) {
        for (final type in ['reading', 'meaning', 'writing', 'usage']) {
          for (var i = 1; i <= 5; i++) {
            final id = 'l$level-$type-00$i';
            final out = shuffledOptions(id, ['正解', 'x', 'y', 'z']);
            counts[out.indexOf('正解')]++;
          }
        }
      }
      // 以前は全問が0番目だった。どの位置にも一定数は来ること。
      for (final c in counts) {
        expect(c, greaterThan(10));
      }
      expect(counts[0], lessThan(60));
    });

    test('選択肢が0〜1個でも落ちない', () {
      expect(shuffledOptions('k', []), isEmpty);
      expect(shuffledOptions('k', ['a']), ['a']);
    });
  });

  testWidgets('模擬試験画面の選択肢は、正解が先頭に固定されず、再描画しても順序が変わらない',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    const options = ['10', '11', '12', '13'];
    const q = EnhancedExamQuestion(
      questionId: 'q1',
      kanji: '森',
      questionType: 'stroke',
      question: '「森」の画数は？',
      options: options,
      correctAnswer: '10', // データ上は先頭(A)が正解
      explanation: '',
      level: 10,
      difficulty: ExamDifficulty.medium,
      category: ExamCategory.stroke,
      averageTimeSeconds: 10,
      correctnessRate: 0,
      userAttempts: 0,
      commonMistakes: [],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        examModeQuestionsProvider.overrideWith((ref) async => [q]),
      ],
      child: MaterialApp(
        home: MockExamEnhancedScreen(config: ExamConfig.standard(level: 10)),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    List<String> displayed() {
      final found = options
          .map((o) => MapEntry(
                o,
                tester.getTopLeft(find.widgetWithText(ElevatedButton, o)).dy,
              ))
          .toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      return found.map((e) => e.key).toList();
    }

    final before = displayed();
    expect(before, shuffledOptions('q1', options));
    expect(before, isNot(options)); // 元の並び(正解がA)のままではない

    // タイマーが進んで再描画されても順序は変わらない
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(displayed(), before);

    await tester.pumpWidget(const SizedBox());
  });
}
