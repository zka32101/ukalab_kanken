import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/level_achievement.dart';

/// 達成度の色の決め方。
///
/// 全部の級で、同じ1色（アプリの色に合わせた桃）にして、割合を色の濃さ（彩度）で表す。
/// 0% は灰色、100% でも派手にならない濃さまで（[maxSaturation]）。割合が高いほど、
/// 明るさを少し落として、100% に近いところの深みを出す（[valueOf]）。
/// 色だけに頼らないよう、画面には割合の数字も添える。
class LevelColors {
  const LevelColors._();

  /// 色相（桃。漢検アプリのテーマ色に合わせる）。
  static const double hue = 330;

  /// 100% のときの彩度。鮮やかすぎない上限にする。
  static const double maxSaturation = 0.50;

  /// 割合を、彩度に変える。平方根にして、割合が小さいうちも色の違いが分かるようにする
  /// （そのままだと、10%以下は灰色とほとんど見分けがつかない）。0 は灰色、1 は [maxSaturation]。
  static double saturationOf(double rate) =>
      math.sqrt(rate.clamp(0.0, 1.0)) * maxSaturation;

  /// 割合を、明るさに変える。高い割合ほど少し暗くして、100% に近いところの深みを出す。
  static double valueOf(double rate) {
    final r = rate.clamp(0.0, 1.0);
    return 0.92 - 0.12 * r * r * r;
  }

  /// [rate]（0.0〜1.0）に応じた色。
  static Color of(double rate) =>
      HSVColor.fromAHSV(1, hue, saturationOf(rate), valueOf(rate)).toColor();

  /// [background] の上に置く文字の色（読みやすい方を選ぶ）。
  static Color textOn(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Colors.white
          : const Color(0xFF1D1B20);
}

/// 達成度の3つの印。「漢字」（覚えた漢字）・「問題」（正解した漢字）・「合計」（その平均）。
/// 色の濃さ（彩度）と数字の両方で、割合を表す。
class LevelAchievementChips extends StatelessWidget {
  const LevelAchievementChips({Key? key, required this.achievement})
      : super(key: key);

  final LevelAchievement achievement;

  /// 画面の読み上げ用。
  static String semanticsLabel(LevelAchievement a) {
    final kanji = '漢字 ${LevelAchievement.percent(a.learnedRate)}パーセント';
    final question = a.hasQuestions
        ? '問題 ${LevelAchievement.percent(a.correctRate)}パーセント'
        : '問題は準備中';
    final total = '合計 ${LevelAchievement.percent(a.totalRate)}パーセント';
    return '$kanji、$question、$total';
  }

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Semantics(
      label: semanticsLabel(a),
      excludeSemantics: true,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _Chip(
            key: ValueKey('achievementKanji_${a.level}'),
            text: '漢字 ${LevelAchievement.percent(a.learnedRate)}%',
            color: LevelColors.of(a.learnedRate),
          ),
          if (a.hasQuestions)
            _Chip(
              key: ValueKey('achievementQuestion_${a.level}'),
              text: '問題 ${LevelAchievement.percent(a.correctRate)}%',
              color: LevelColors.of(a.correctRate),
            )
          else
            _Chip(
              key: ValueKey('achievementQuestion_${a.level}'),
              text: '問題 準備中',
              color: LevelColors.of(0),
            ),
          _Chip(
            key: ValueKey('achievementTotal_${a.level}'),
            text: '合計 ${LevelAchievement.percent(a.totalRate)}%',
            color: LevelColors.of(a.totalRate),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({Key? key, required this.text, required this.color})
      : super(key: key);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: LevelColors.textOn(color),
        ),
      ),
    );
  }
}
