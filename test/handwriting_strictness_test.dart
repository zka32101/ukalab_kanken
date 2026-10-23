import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/stroke_order_sample_data.dart';
import 'package:kanken/screens/settings_screen.dart';
import 'package:kanken/services/handwriting_judge_service.dart';
import 'package:kanken/services/handwriting_strictness.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<List<List<double>>> _drawn() {
  final ref = StrokeOrderSampleData.getStrokeOrder('百')!;
  final polys = HandwritingJudgeService.referencePolylines(ref.strokePaths, ref.viewBox);
  return [
    for (final s in polys) [for (final p in s) [p.dx * 3 + 20, p.dy * 3 + 40]],
  ];
}

Future<HandwritingJudgement> _judge(int pass) => HandwritingJudgeService().judgeHandwriting(
      strokes: _drawn(),
      correctAnswer: {'kanji': '百'},
      canvasSize: [360, 500],
      passingScore: pass,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('合格点は 50/60/65/70/75/80、既定は65（小学生向けの50点を足した）', () {
    expect(HandwritingStrictness.values.map((e) => e.passingScore), [50, 60, 65, 70, 75, 80]);
    expect(HandwritingStrictness.kids.passingScore, 50);
    expect(HandwritingStrictness.easy.passingScore, 60);
    expect(HandwritingStrictness.standard.passingScore, 65);
    expect(HandwritingStrictness.firm.passingScore, 75);
    expect(HandwritingStrictness.normal.passingScore, 70);
    expect(HandwritingStrictness.strict.passingScore, 80);
    expect(HandwritingStrictness.defaultLevel, HandwritingStrictness.standard);
    expect(HandwritingJudgeService.passingScore, 65);
  });

  test('同じ点数でも合格点で正誤が変わる（点数自体は不変）', () async {
    final base = await _judge(70);
    final score = (base.confidence * 100).round();
    final easy = await _judge(score - 1);
    final strict = await _judge(score + 1);
    expect((easy.confidence * 100).round(), score);
    expect((strict.confidence * 100).round(), score);
    expect(easy.isCorrect, isTrue);
    expect(strict.isCorrect, isFalse);
    expect(strict.message, startsWith('もう一度'));
    expect((await _judge(score)).isCorrect, isTrue);
  });

  test('保存値なしは65点、保存して読み戻せる、壊れた値は65点、旧保存名normalは70点のまま', () async {
    expect(await HandwritingStrictnessStore.load(), HandwritingStrictness.standard);
    for (final l in HandwritingStrictness.values) {
      await HandwritingStrictnessStore.save(l);
      expect(await HandwritingStrictnessStore.load(), l);
    }
    SharedPreferences.setMockInitialValues({HandwritingStrictnessStore.prefsKey: 'xxx'});
    expect(await HandwritingStrictnessStore.load(), HandwritingStrictness.standard);
    SharedPreferences.setMockInitialValues({HandwritingStrictnessStore.prefsKey: 'normal'});
    expect(await HandwritingStrictnessStore.load(), HandwritingStrictness.normal);
  });

  testWidgets('設定タイルで選ぶと保存される', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: Scaffold(body: HandwritingStrictnessTile())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('手書きの判定'), findsOneWidget);
    await tester.tap(find.text('65点'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('80点').last);
    await tester.pumpAndSettle();
    expect(await HandwritingStrictnessStore.load(), HandwritingStrictness.strict);
  });
}
