import 'dart:math';
import 'dart:ui' show Offset;

import 'package:path_drawing/path_drawing.dart';

import '../data/handwriting_confusables.dart';
import '../data/stroke_order_sample_data.dart';

/// 手書き判定サービス
/// ストローク座標と正解パターンの照合ロジック
///
/// 実際の字形一致判定（機械学習モデル等）は行わない。国語コレ
/// (drawing_canvas_screen.dart の _calculateScore()) と同様の
/// ヒューリスティック採点方式を採用する:
/// - ストローク数（画数の目安、最大25点）
/// - 中心位置（キャンバス中心からの距離、最大40点）
/// - サイズ（キャンバスに対する占有率、最大35点）
class HandwritingJudgeService {
  /// 合格とみなす点数（0-100）
  static const int passingScore = 65;

  /// 字として小さすぎる入力（キャンバス短辺に対する外接四角の長辺の割合）は採点しない
  static const double minInkExtentRatio = 0.12;
  /// 書いた線の総延長が正解の何倍までなら減点しないか（書き散らし対策）。
  static const double maxInkRatio = 2.0;

  /// ストロークデータから手書き入力を判定
  /// @param strokes: 手書きストローク座標群（キャンバス内のローカル座標）。
  ///   ストロークごとにリストを分けて渡す（ペンを離した箇所が正しくストロークの
  ///   区切りとして扱われる。距離ベースの推測分割は行わない）。
  /// @param correctAnswer: 正解の漢字パターンデータ（strokeCountを含む）
  /// @param canvasSize: 手書き入力エリアの [幅, 高さ]（ヒューリスティック採点の基準）
  /// @return 正解判定結果（0-100点のヒューリスティックスコア）
  Future<HandwritingJudgement> judgeHandwriting({
    required List<List<List<double>>> strokes,
    required Map<String, dynamic> correctAnswer,
    List<double>? canvasSize,
    int passingScore = HandwritingJudgeService.passingScore,
  }) async {
    try {
      final allPoints = strokes.expand((s) => s).toList();
      if (allPoints.isEmpty) {
        return HandwritingJudgement(
          isCorrect: false,
          confidence: 0.0,
          message: '入力がありません',
        );
      }

      final canvasW = (canvasSize != null && canvasSize.isNotEmpty) ? canvasSize[0] : 280.0;
      final canvasH = (canvasSize != null && canvasSize.length > 1) ? canvasSize[1] : 280.0;

      // 書き順データ(KanjiVG)がある漢字は、字形を照合して採点する。ない漢字だけ、
      // 従来の画数・位置・大きさの目安で採点する。
      final kanji = correctAnswer['kanji'] as String?;
      final ref = kanji == null ? null : StrokeOrderSampleData.getStrokeOrder(kanji);
      final score = ref == null
          ? _calculateScore(strokes, allPoints, canvasW, canvasH)
          : shapeScore(
              strokes: strokes,
              referenceStrokes: referencePolylines(ref.strokePaths, ref.viewBox),
              canvasSize: [canvasW, canvasH],
            );
      var isCorrect = score >= passingScore;

      // 形が似た別の字(提と堤など)を書いていないか。合格点を超えても、似た字の基準のほうが
      // 書いた形に近ければ、別の字を書いたとみなして不合格にする。
      if (isCorrect && ref != null && kanji != null) {
        final other = closerConfusable(
          kanji: kanji,
          targetScore: score,
          strokes: strokes,
          canvasSize: [canvasW, canvasH],
        );
        if (other != null) {
          return HandwritingJudgement(
            isCorrect: false,
            confidence: score / 100,
            message: '形が似た別の字に近いようです。もう一度ていねいに書いてみましょう（$score点）',
          );
        }
      }

      return HandwritingJudgement(
        isCorrect: isCorrect,
        confidence: score / 100,
        message: isCorrect ? '正解（$score点）' : 'もう一度書いてみましょう（$score点）',
      );
    } catch (e) {
      return HandwritingJudgement(
        isCorrect: false,
        confidence: 0.0,
        message: '判定エラー：${e.toString()}',
      );
    }
  }

  /// [kanji] と形が似た字([kHandwritingConfusables])のうち、書いた線の形が [kanji] より
  /// 近いもの(点数が [targetScore] を上回る字)を返す。なければ null。
  /// 基準データがない字は見ない。正しく書いた字は、基準との点数が最も高くなるので、
  /// 似た字に負けない。
  static String? closerConfusable({
    required String kanji,
    required int targetScore,
    required List<List<List<double>>> strokes,
    List<double>? canvasSize,
  }) {
    final candidates = kHandwritingConfusables[kanji];
    if (candidates == null) return null;
    for (final c in candidates.split('')) {
      final d = StrokeOrderSampleData.getStrokeOrder(c);
      if (d == null) continue;
      final other = shapeScore(
        strokes: strokes,
        referenceStrokes: referencePolylines(d.strokePaths, d.viewBox),
        canvasSize: canvasSize,
      );
      if (other > targetScore) return c;
    }
    return null;
  }

  /// 書き順データの各画（SVGパス）を、点列に直す。
  static List<List<Offset>> referencePolylines(List<String> svgPaths, double viewBox) {
    final result = <List<Offset>>[];
    for (final svg in svgPaths) {
      final pts = <Offset>[];
      for (final m in parseSvgPathData(svg).computeMetrics()) {
        final n = max(2, (m.length / 3).ceil());
        for (var i = 0; i <= n; i++) {
          final t = m.getTangentForOffset(m.length * i / n);
          if (t != null) pts.add(t.position);
        }
      }
      result.add(pts);
    }
    return result;
  }

  /// 字形の一致度(0-100)。位置と大きさは正規化して無視し、形だけを見る。
  /// - 正解の各点が、書いた線のどこかの近くにあること（書き漏れ）
  /// - 書いた各点が、正解の線のどこかの近くにあること（余計な線）
  /// - 画数が大きく違う場合は減点（±1画までは許す）
  static int shapeScore({
    required List<List<List<double>>> strokes,
    required List<List<Offset>> referenceStrokes,
    List<double>? canvasSize,
  }) {
    final user = [
      for (final s in strokes)
        if (s.isNotEmpty) [for (final p in s) Offset(p[0], p[1])],
    ];
    if (user.isEmpty || referenceStrokes.isEmpty) return 0;
    // 点や極小の書き込みは、正規化で拡大されて字形に見えてしまうので先に弾く
    if (canvasSize != null && canvasSize.length > 1) {
      final all = user.expand((s) => s);
      final xs = all.map((p) => p.dx), ys = all.map((p) => p.dy);
      final extent = max(xs.reduce(max) - xs.reduce(min), ys.reduce(max) - ys.reduce(min));
      if (extent < min(canvasSize[0], canvasSize[1]) * minInkExtentRatio) return 0;
    }
    final u = _resample(_normalize(user));
    final r = _resample(_normalize(referenceStrokes));
    if (u.isEmpty || r.isEmpty) return 0;

    double mean(List<Offset> from, List<Offset> to) {
      var sum = 0.0;
      for (final a in from) {
        var best = double.infinity;
        for (final b in to) {
          best = min(best, (a - b).distance);
        }
        sum += best;
      }
      return sum / from.length;
    }

    // 書き漏れ(r→u)と余計な線(u→r)の平均に加え、どちらか悪い方も効かせる
    final miss = mean(r, u), extra = mean(u, r);
    final dist = ((miss + extra) / 2) * 0.6 + max(miss, extra) * 0.4; // 0〜約1（正規化済み）
    final shape = (100 * (1 - (dist / 0.14))).clamp(0.0, 100.0);
    final diff = (user.length - referenceStrokes.length).abs();
    final penalty = diff <= 1 ? 0.0 : (diff - 1) * 15.0;
    // 線を塗りつぶすように書き散らすと、どこも正解の近くになって形の一致度が高く出てしまう。
    // 書いた線の総延長が正解の2倍を超えたら、超えた分だけ減点する。
    final inkRatio = _pathLength(_normalize(user)) / max(_pathLength(_normalize(referenceStrokes)), 1e-6);
    final inkPenalty = inkRatio <= maxInkRatio ? 0.0 : ((inkRatio - maxInkRatio) * 40.0).clamp(0.0, 60.0);
    return (shape - penalty - inkPenalty).clamp(0.0, 100.0).round();
  }

  static double _pathLength(List<List<Offset>> strokes) {
    var sum = 0.0;
    for (final s in strokes) {
      for (var i = 0; i + 1 < s.length; i++) {
        sum += (s[i + 1] - s[i]).distance;
      }
    }
    return sum;
  }

  /// 全体の外接四角を、縦横比を保って単位正方形(中央寄せ)に収める。
  static List<List<Offset>> _normalize(List<List<Offset>> strokes) {
    final all = strokes.expand((s) => s);
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in all) {
      minX = min(minX, p.dx);
      maxX = max(maxX, p.dx);
      minY = min(minY, p.dy);
      maxY = max(maxY, p.dy);
    }
    final side = max(max(maxX - minX, maxY - minY), 1e-6);
    final ox = (1 - (maxX - minX) / side) / 2;
    final oy = (1 - (maxY - minY) / side) / 2;
    return [
      for (final s in strokes)
        [for (final p in s) Offset((p.dx - minX) / side + ox, (p.dy - minY) / side + oy)],
    ];
  }

  /// 線に沿って、一定間隔の点に取り直す（点の粗密に左右されないように）。
  static List<Offset> _resample(List<List<Offset>> strokes, {double step = 0.02}) {
    final out = <Offset>[];
    for (final s in strokes) {
      if (s.length == 1) out.add(s.first);
      for (var i = 0; i + 1 < s.length; i++) {
        final a = s[i], b = s[i + 1];
        final len = (b - a).distance;
        final n = max(1, (len / step).ceil());
        for (var k = 0; k < n; k++) {
          out.add(Offset.lerp(a, b, k / n)!);
        }
      }
      if (s.length > 1) out.add(s.last);
    }
    return out;
  }

  /// 採点ロジック（国語コレの _calculateScore() を移植）
  /// - ストローク数：1〜5画が理想（最大25点）
  /// - 中心位置：バウンディングボックス中心とキャンバス中心の距離が近いほど高得点（最大40点）
  /// - サイズ：キャンバスの20%〜55%を占めるのが理想（最大35点）
  int _calculateScore(
    List<List<List<double>>> strokes,
    List<List<double>> allPoints,
    double canvasW,
    double canvasH,
  ) {
    if (allPoints.isEmpty || strokes.isEmpty) return 0;

    double minX = allPoints.first[0], maxX = allPoints.first[0];
    double minY = allPoints.first[1], maxY = allPoints.first[1];
    for (final p in allPoints) {
      minX = min(minX, p[0]);
      maxX = max(maxX, p[0]);
      minY = min(minY, p[1]);
      maxY = max(maxY, p[1]);
    }

    final bbW = maxX - minX;
    final bbH = maxY - minY;
    final bbCx = (minX + maxX) / 2;
    final bbCy = (minY + maxY) / 2;

    // 1. ストローク数スコア（1-5画が理想）
    final sc = strokes.length;
    final int strokeScore;
    if (sc == 0) {
      strokeScore = 0;
    } else if (sc == 1) {
      strokeScore = 12;
    } else if (sc <= 5) {
      strokeScore = 25;
    } else if (sc <= 8) {
      strokeScore = (25 - (sc - 5) * 5).clamp(5, 25);
    } else {
      strokeScore = 5;
    }

    // 2. 中心位置スコア（中心から20%以内が理想）
    final dxRatio = ((bbCx - canvasW / 2) / canvasW).abs();
    final dyRatio = ((bbCy - canvasH / 2) / canvasH).abs();
    final centerDist = (dxRatio + dyRatio) / 2;
    final centerScore = (40 * (1 - centerDist * 4.0)).clamp(0.0, 40.0).round();

    // 3. サイズスコア（キャンバスの20%〜55%が理想）
    final wRatio = bbW / canvasW;
    final hRatio = bbH / canvasH;
    final sizeRatio = (wRatio + hRatio) / 2;
    final int sizeScore;
    if (sizeRatio < 0.08) {
      sizeScore = (sizeRatio * 100).round().clamp(0, 10);
    } else if (sizeRatio < 0.20) {
      sizeScore = (10 + (sizeRatio - 0.08) * 200).round().clamp(10, 35);
    } else if (sizeRatio <= 0.55) {
      final dist = (sizeRatio - 0.37).abs();
      sizeScore = (35 - dist * 80).clamp(10.0, 35.0).round();
    } else {
      sizeScore = (35 - (sizeRatio - 0.55) * 70).clamp(5.0, 35.0).round();
    }

    return (strokeScore + centerScore + sizeScore).clamp(0, 100);
  }
}

class HandwritingJudgement {
  final bool isCorrect;
  final double confidence; // 0.0 ~ 1.0
  final String message;

  HandwritingJudgement({
    required this.isCorrect,
    required this.confidence,
    required this.message,
  });
}
