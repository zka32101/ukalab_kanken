import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/handwriting_confusables.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/data/stroke_order_sample_data.dart';
import 'package:kanken/services/handwriting_judge_service.dart';

/// 基準の字形そのままを、280pxのキャンバスに書いた線として返す(きれいに書いた字)。
List<List<List<double>>> written(String kanji) {
  final d = StrokeOrderSampleData.getStrokeOrder(kanji)!;
  final polys = HandwritingJudgeService.referencePolylines(d.strokePaths, d.viewBox);
  return [
    for (final s in polys) [for (final p in s) [p.dx * 280 / 109, p.dy * 280 / 109]],
  ];
}

Future<bool> judge(String drawn, String target) async {
  final r = await HandwritingJudgeService().judgeHandwriting(
    strokes: written(drawn),
    correctAnswer: {'kanji': target},
    canvasSize: const [280, 280],
  );
  return r.isCorrect;
}

void main() {
  test('似た字を書いたら、別の字として不合格になる(提と堤など)', () async {
    const pairs = [
      '提堤', '末未', '大太', '大犬', '王玉', '待侍', '持特', '苦若', '休体', '技枝', '土士',
    ];
    for (final p in pairs) {
      final a = p[0], b = p[1];
      expect(await judge(a, b), isFalse, reason: '$aを書いて$bの答えに合格した');
      expect(await judge(b, a), isFalse, reason: '$bを書いて$aの答えに合格した');
    }
  });

  test('正しい字を書いたら、合格する(似た字がある字でも)', () async {
    for (final k in ['提', '堤', '末', '未', '大', '太', '犬', '王', '玉', '待', '侍', '持', '特']) {
      expect(await judge(k, k), isTrue, reason: '$kを書いて$kの答えが不合格');
    }
  });

  test('10級〜2級の全字を、きれいに書いたら、全部合格する(似た字の判定で落ちない)', () async {
    const levels = [
      'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5',
      'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2',
    ];
    final failed = <String>[];
    var n = 0;
    for (final l in levels) {
      for (final k in LevelKanjiData.forLevel(l)) {
        if (StrokeOrderSampleData.getStrokeOrder(k) == null) continue;
        n++;
        if (!await judge(k, k)) failed.add(k);
      }
    }
    expect(n, greaterThan(2000));
    expect(failed, isEmpty, reason: '合格しなかった字: ${failed.join()}');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('似た字の一覧は、自分自身を含まず、基準データがある字だけ', () {
    for (final e in kHandwritingConfusables.entries) {
      expect(e.value.contains(e.key), isFalse, reason: e.key);
      expect(StrokeOrderSampleData.getStrokeOrder(e.key), isNotNull, reason: e.key);
      for (final c in e.value.split('')) {
        expect(StrokeOrderSampleData.getStrokeOrder(c), isNotNull, reason: '${e.key}→$c');
      }
    }
  });

  test('一覧は対称(AがBに似ていれば、BもAに似ている。上限8字の範囲で)', () {
    var asym = 0;
    for (final e in kHandwritingConfusables.entries) {
      for (final c in e.value.split('')) {
        final back = kHandwritingConfusables[c];
        if (back == null || !back.contains(e.key)) asym++;
      }
    }
    // 上限8字で切るので、完全な対称にはならない。ほとんどは対称であること。
    final total = kHandwritingConfusables.values.fold<int>(0, (a, v) => a + v.length);
    expect(asym / total, lessThan(0.5));
  });
}
