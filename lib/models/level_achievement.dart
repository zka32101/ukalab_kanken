import '../data/level_kanji_data.dart';

/// 級の並び（易しい級から順）。ホームの一覧・達成度の集計は、この順に並べる。
const List<String> kKankenLevels = [
  'LEVEL_10',
  'LEVEL_9',
  'LEVEL_8',
  'LEVEL_7',
  'LEVEL_6',
  'LEVEL_5',
  'LEVEL_4',
  'LEVEL_3',
  'LEVEL_2_PRE',
  'LEVEL_2',
  'LEVEL_1_PRE',
  'LEVEL_1',
];

/// 問題が用意されている級。
///
/// 漢字（配当漢字）はどの級にもあるが、問題は 10級〜3級までしか入っていない
/// （準2級・2級・準1級・1級は準備中）。問題を足したら、ここにも足す。
const Set<String> kLevelsWithQuestions = {
  'LEVEL_10',
  'LEVEL_9',
  'LEVEL_8',
  'LEVEL_7',
  'LEVEL_6',
  'LEVEL_5',
  'LEVEL_4',
  'LEVEL_3',
};

/// questionStats の1件が「一度でも正解した」を表すか。
///
/// 新しい記録は `everCorrect` を持つ。それ以前の記録は `correctStreak`（連続正解数）しか
/// 無いので、1以上なら正解したことがある、とみなす（間違えて0に戻った分は、数えられない）。
bool questionStatCountsAsCorrect(Map<String, dynamic> data) {
  if (data['everCorrect'] == true) return true;
  final streak = data['correctStreak'];
  return streak is num && streak >= 1;
}

/// 級ごとの達成度。漢字（学んだ）と問題（正解した）の2種類を、それぞれ配当漢字に対する割合で表す。
class LevelAchievement {
  const LevelAchievement({
    required this.level,
    required this.totalKanji,
    required this.learnedKanji,
    required this.correctKanji,
    required this.hasQuestions,
  });

  final String level;

  /// 配当漢字の数。
  final int totalKanji;

  /// 「覚えた」にした漢字の数。
  final int learnedKanji;

  /// 一度でも正解した漢字の数（重複なし）。
  final int correctKanji;

  /// この級の問題が用意されているか。無いときは、問題の割合は出さない。
  final bool hasQuestions;

  /// 漢字（学んだ）の割合。0.0〜1.0。
  double get learnedRate => _rate(learnedKanji);

  /// 問題（正解した）の割合。0.0〜1.0。
  double get correctRate => _rate(correctKanji);

  /// 合計の割合。漢字と問題の平均。問題が用意されていない級は、漢字の割合だけ。
  double get totalRate =>
      hasQuestions ? (learnedRate + correctRate) / 2 : learnedRate;

  double _rate(int n) =>
      totalKanji <= 0 ? 0.0 : (n / totalKanji).clamp(0.0, 1.0);

  /// 「45%」のような表示用の整数のパーセント。
  static int percent(double rate) => (rate * 100).round();

  static LevelAchievement empty(String level) => LevelAchievement(
        level: level,
        totalKanji: LevelKanjiData.forLevel(level).length,
        learnedKanji: 0,
        correctKanji: 0,
        hasQuestions: kLevelsWithQuestions.contains(level),
      );

  /// [learnedIds]・[correctIds] は、問題IDの集合（例: `LEVEL_9-毎`）。IDの前半が級、後半が漢字。
  /// 配当漢字に無い漢字のIDは数えない（割合が100%を超えないように）。
  static Map<String, LevelAchievement> compute({
    required Iterable<String> levels,
    required Set<String> learnedIds,
    required Set<String> correctIds,
  }) {
    int countFor(String level, Set<String> ids, Set<String> allowed) {
      final prefix = '$level-';
      var n = 0;
      for (final id in ids) {
        if (id.startsWith(prefix) &&
            allowed.contains(id.substring(prefix.length))) n++;
      }
      return n;
    }

    return {
      for (final level in levels)
        level: () {
          final kanji = LevelKanjiData.forLevel(level);
          final allowed = kanji.toSet();
          return LevelAchievement(
            level: level,
            totalKanji: kanji.length,
            learnedKanji: countFor(level, learnedIds, allowed),
            correctKanji: countFor(level, correctIds, allowed),
            hasQuestions: kLevelsWithQuestions.contains(level),
          );
        }(),
    };
  }
}
