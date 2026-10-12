
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/stroke_order_sample_data.dart';
import 'package:kanken/services/handwriting_judge_service.dart';

/// 正解データを、キャンバス座標（拡大・平行移動）の「書いた線」に変換する。
List<List<List<double>>> _drawn(String kanji, {double scale = 3, double dx = 20, double dy = 40}) {
  final ref = StrokeOrderSampleData.getStrokeOrder(kanji)!;
  final polys = HandwritingJudgeService.referencePolylines(ref.strokePaths, ref.viewBox);
  return [
    for (final s in polys) [for (final p in s) [p.dx * scale + dx, p.dy * scale + dy]],
  ];
}

Future<bool> _ok(String kanji, List<List<List<double>>> strokes) async {
  final j = await HandwritingJudgeService().judgeHandwriting(
    strokes: strokes,
    correctAnswer: {'kanji': kanji},
    canvasSize: [360, 500],
  );
  return j.isCorrect;
}

void main() {
  test('正しい字形は、位置・大きさが違っても正解になる', () async {
    expect(await _ok('百', _drawn('百')), isTrue);
    expect(await _ok('百', _drawn('百', scale: 2, dx: 100, dy: 200)), isTrue);
  });

  test('斜めの線1本は、「百」として不正解', () async {
    final line = [
      [
        [100.0, 150.0],
        [260.0, 400.0],
      ],
    ];
    expect(await _ok('百', line), isFalse);
  });

  test('別の漢字の形は不正解', () async {
    expect(await _ok('百', _drawn('水')), isFalse);
    expect(await _ok('水', _drawn('百')), isFalse);
  });

  test('少し手ぶれしても正解になる', () async {
    final shaky = [
      for (final s in _drawn('学'))
        [for (var i = 0; i < s.length; i++) [s[i][0] + (i.isEven ? 3 : -3), s[i][1] + (i % 3 == 0 ? 3 : -2)]],
    ];
    expect(await _ok('学', shaky), isTrue);
  });

  test('画数が大きく違うと不正解（同じ形に余計な線を足す）', () async {
    final extra = [
      ..._drawn('一'),
      [
        [60.0, 100.0],
        [60.0, 300.0],
      ],
      [
        [200.0, 100.0],
        [200.0, 300.0],
      ],
      [
        [300.0, 100.0],
        [300.0, 300.0],
      ],
    ];
    expect(await _ok('一', extra), isFalse);
  });

  test('何も書いていなければ不正解', () async {
    expect(await _ok('百', const []), isFalse);
  });

  test('書き順データにある漢字は、すべて自分の字形を正解にできる', () async {
    final bad = <String>[];
    for (final k in StrokeOrderSampleData.availableKanji) {
      if (!await _ok(k, _drawn(k))) bad.add(k);
    }
    expect(bad, isEmpty);
  });
}
