import '../data/level_kanji_data.dart';
import '../data/local_exam_questions.dart';
import '../models/category_label.dart';
import '../models/mock_exam_modes.dart';

/// 「収録問題数」の一覧の、1つの級ぶん。
class ContentCountRow {
  const ContentCountRow({
    required this.level,
    required this.kanjiCount,
    required this.counts,
  });

  /// 'LEVEL_10' など。
  final String level;

  /// この級の配当漢字の数。
  final int kanjiCount;

  /// 分野の日本語名 -> 出せる問題の数(0より大きい分野だけ。出題順)。
  final Map<String, int> counts;

  int get total => counts.values.fold(0, (a, b) => a + b);
}

/// 一覧に出す級(やさしい級から)。
const List<String> kContentCountLevels = [
  'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5',
  'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1',
];

/// 級ごとの、配当漢字数と、演習で出せる問題数(分野ごと)。
/// 数はアプリのデータから数えるので、問題を足せば、一覧も自動で変わる。
/// 「出せる数」は、その級以下のやさしい級の問題も含む(上の級ほど増える)。
List<ContentCountRow> buildContentCounts() {
  return [
    for (final level in kContentCountLevels)
      ContentCountRow(
        level: level,
        kanjiCount: LevelKanjiData.forLevel(level).length,
        counts: {
          for (final c in kLocalExamCategories)
            if (examPoolSize(c, level) > 0) categoryLabel(c.name): examPoolSize(c, level),
        },
      ),
  ];
}
