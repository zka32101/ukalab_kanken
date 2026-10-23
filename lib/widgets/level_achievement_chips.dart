import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/level_achievement.dart';

/// 級ごとの色の濃さ（彩度）の決め方。
///
/// 級ごとに色相（色合い）を変え、達成の割合を彩度にする（[saturationOf]）。0% は灰色、100% は鮮やかな色。
/// 明るさは一定にして、彩度だけで違いが分かるようにする。色だけに頼らないよう、
/// 画面には割合の数字も添える。
class LevelColors {
  const LevelColors._();

  /// 級の並び（[kKankenLevels]）の順に、色相を30度ずつずらす。
  static double hueOf(String level) {
    final i = kKankenLevels.indexOf(level);
    return ((i < 0 ? 0 : i) * 30.0) % 360;
  }

  /// 割合を、彩度に変える。平方根にして、割合が小さいうちも色の違いが分かるようにする
  /// （そのままだと、10%以下は灰色とほとんど見分けがつかない）。0 は灰色、1 は最も鮮やか。
  static double saturationOf(double rate) => math.sqrt(rate.clamp(0.0, 1.0));

  /// [rate]（0.0〜1.0）に応じた色。
  static Color of(String level, double rate) {
    return HSVColor.fromAHSV(1, hueOf(level), saturationOf(rate), 0.86)
        .toColor();
  }

  /// [background] の上に置く文字の色（読みやすい方を選ぶ）。
  static Color textOn(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Colors.white
          : const Color(0xFF1D1B20);
}

/// 達成度の2つの印。左が「漢字」（覚えた漢字）、右が「問題」（正解した漢字）。
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
    return '$kanji、$question';
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
            color: LevelColors.of(a.level, a.learnedRate),
          ),
          if (a.hasQuestions)
            _Chip(
              key: ValueKey('achievementQuestion_${a.level}'),
              text: '問題 ${LevelAchievement.percent(a.correctRate)}%',
              color: LevelColors.of(a.level, a.correctRate),
            )
          else
            _Chip(
              key: ValueKey('achievementQuestion_${a.level}'),
              text: '問題 準備中',
              color: LevelColors.of(a.level, 0),
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
