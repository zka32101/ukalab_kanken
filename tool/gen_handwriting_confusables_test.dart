// 手書き判定で「形が似た別の字」を見分けるための一覧(lib/data/handwriting_confusables.dart)を作る道具。
//
//   flutter test tool/gen_handwriting_confusables_test.dart
//
// 10級〜2級の全漢字の字形の基準データどうしを、手書き判定と同じ採点(shapeScore)で照合し、
// 点数が高い(=形が似ている)組を、漢字ごとに最大8字まで残す。全ペアは約450万だが、画数が
// 2画以上違う組は似ていないので飛ばす。結果のファイルだけをコミットする(この道具は再生成用)。
import 'dart:io';
import 'dart:ui' show Offset;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/data/stroke_order_sample_data.dart';
import 'package:kanken/services/handwriting_judge_service.dart';

const _minScore = 55; // これ以上の点数の組を「似ている」とする
const _maxPerKanji = 8;

void main() {
  test('generate confusables', () {
    const levels = [
      'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5',
      'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2',
    ];
    final kanji = [for (final l in levels) ...LevelKanjiData.forLevel(l)];
    final polys = <String, List<List<Offset>>>{};
    final inputs = <String, List<List<List<double>>>>{};
    for (final k in kanji) {
      final d = StrokeOrderSampleData.getStrokeOrder(k);
      if (d == null) continue;
      final p = HandwritingJudgeService.referencePolylines(d.strokePaths, d.viewBox);
      polys[k] = p;
      // 280pxのキャンバスに書いた線として扱う(基準のviewBoxは109)。
      inputs[k] = [for (final s in p) [for (final o in s) [o.dx * 280 / 109, o.dy * 280 / 109]]];
    }
    final keys = polys.keys.toList()..sort();
    final found = <String, List<MapEntry<String, int>>>{};
    final sw = Stopwatch()..start();
    for (var i = 0; i < keys.length; i++) {
      for (var j = i + 1; j < keys.length; j++) {
        final a = keys[i], b = keys[j];
        if ((polys[a]!.length - polys[b]!.length).abs() > 1) continue;
        final s = HandwritingJudgeService.shapeScore(
          strokes: inputs[a]!,
          referenceStrokes: polys[b]!,
          canvasSize: const [280, 280],
        );
        if (s >= _minScore) {
          found.putIfAbsent(a, () => []).add(MapEntry(b, s));
          found.putIfAbsent(b, () => []).add(MapEntry(a, s));
        }
      }
      if (i % 200 == 0) {
        // ignore: avoid_print
        print('progress $i/${keys.length} ${sw.elapsed.inSeconds}s');
      }
    }
    final out = StringBuffer()
      ..writeln('// GENERATED FILE - do not edit by hand. Run tool/gen_handwriting_confusables_test.dart.')
      ..writeln('//')
      ..writeln('// 手書き判定で、形が似た別の字に当たりやすい漢字の一覧(10級〜2級)。')
      ..writeln('// 基準の字形どうしを手書き判定と同じ採点で照合し、$_minScore点以上の組を、点の高い順に最大$_maxPerKanji字まで。')
      ..writeln('')
      ..writeln('const Map<String, String> kHandwritingConfusables = {');
    final sorted = found.keys.toList()..sort();
    for (final k in sorted) {
      final list = found[k]!..sort((x, y) => y.value.compareTo(x.value));
      final chars = list.take(_maxPerKanji).map((e) => e.key).join();
      out.writeln("  '$k': '$chars',");
    }
    out.writeln('};');
    File('lib/data/handwriting_confusables.dart').writeAsStringSync(out.toString());
    // ignore: avoid_print
    print('done kanji=${keys.length} withConfusables=${sorted.length} ${sw.elapsed.inSeconds}s');
  }, timeout: const Timeout(Duration(minutes: 90)));
}
