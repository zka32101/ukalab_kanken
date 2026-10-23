import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/data/stroke_order_sample_data.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';
import 'package:kanken/widgets/stroke_highlight_view.dart';

/// 漢検の「筆順」（赤い画は何画目？）に合わせた演習。
void main() {
  test('筆順は、漢検で出題される10級〜5級だけに出る', () {
    for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5']) {
      expect(availableModesForLevel(l), contains(PracticeMode.strokeOrder), reason: l);
    }
    for (final l in ['LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1']) {
      expect(availableModesForLevel(l), isNot(contains(PracticeMode.strokeOrder)), reason: l);
    }
  });

  group('選択肢', () {
    test('4つ・正解を含む・1〜画数の範囲・重複なし・小さい順', () {
      final random = Random(3);
      for (var total = 4; total <= 25; total++) {
        for (var answer = 1; answer <= total; answer++) {
          final ch = strokeOrderChoices(answer, total, random)!;
          expect(ch.length, 4, reason: '$answer/$total');
          expect(ch, contains(answer), reason: '$answer/$total');
          expect(ch.toSet().length, 4, reason: '$answer/$total');
          expect(ch.every((n) => n >= 1 && n <= total), isTrue, reason: '$answer/$total');
          expect([...ch]..sort(), ch, reason: '$answer/$total');
        }
      }
    });

    test('4画未満の字や範囲外の番号では作らない（画数の問題に回す）', () {
      expect(strokeOrderChoices(1, 3, Random(1)), isNull);
      expect(strokeOrderChoices(2, 1, Random(1)), isNull);
      expect(strokeOrderChoices(0, 8, Random(1)), isNull);
      expect(strokeOrderChoices(9, 8, Random(1)), isNull);
    });

    test('10級〜5級の4画以上の字は、どの画でも選択肢が作れる', () {
      final random = Random(5);
      for (final l in ['LEVEL_10', 'LEVEL_7', 'LEVEL_5']) {
        for (final k in LevelKanjiData.forLevel(l)) {
          final data = StrokeOrderSampleData.getStrokeOrder(k);
          if (data == null || data.strokeCount < 4) continue;
          for (var i = 1; i <= data.strokeCount; i++) {
            expect(strokeOrderChoices(i, data.strokeCount, random), isNotNull, reason: '$k $i');
          }
        }
      }
    });
  });

  group('赤い画の図', () {
    testWidgets('書き順のある字は、図が描ける（画数の多い字でもオーバーフローしない）', (tester) async {
      final data = StrokeOrderSampleData.getStrokeOrder('森')!;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: StrokeHighlightView(data: data, highlightIndex: data.strokeCount - 1, size: 180),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(StrokeHighlightView), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('「森」の12画目を赤で示した図')), findsOneWidget);
    });

    testWidgets('赤い画を変えると、図の説明も変わる', (tester) async {
      final data = StrokeOrderSampleData.getStrokeOrder('校')!;
      for (final i in [0, 4]) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: StrokeHighlightView(data: data, highlightIndex: i, size: 120)),
        ));
        expect(find.bySemanticsLabel(RegExp('「校」の${i + 1}画目')), findsOneWidget, reason: '$i');
      }
    });
  });
}
