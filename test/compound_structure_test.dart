import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/compound_structure_data.dart';
import 'package:kanken/data/level_kanji_data.dart';

/// 漢検の「熟語の構成」（ア〜オ）の演習データ。
void main() {
  const levels = ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2'];
  final allKanji = <String>{for (final l in levels) ...LevelKanjiData.forLevel(l)};

  test('語は2字・読みはひらがな・配当漢字だけ・重複なし', () {
    final seen = <String>{};
    for (final q in CompoundStructureData.all) {
      expect(q.jukugo.runes.length, 2, reason: q.jukugo);
      expect(allKanji.containsAll(q.jukugo.split('')), isTrue, reason: q.jukugo);
      expect(RegExp(r'^[ぁ-ゖー]+$').hasMatch(q.reading), isTrue, reason: '${q.jukugo} ${q.reading}');
      expect(seen.add(q.jukugo), isTrue, reason: '${q.jukugo} が重複');
    }
  });

  test('5つの種類（ア〜オ）が、どれも十分な数ある', () {
    for (final t in CompoundStructureType.values) {
      expect(CompoundStructureData.all.where((q) => q.structureType == t).length, greaterThanOrEqualTo(30), reason: '$t');
    }
    expect(compoundStructureLabels.length, 5);
  });

  test('打ち消し（オ）の語は、不・無・非・未で始まる', () {
    for (final q in CompoundStructureData.all.where((q) => q.structureType == CompoundStructureType.negation)) {
      expect('不無非未'.contains(q.jukugo[0]), isTrue, reason: q.jukugo);
    }
  });

  test('上の級ほど出せる語が増える。4級〜2級・準1級・1級でも出せる', () {
    final counts = [for (final l in ['LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) CompoundStructureData.forLevel(l).length];
    for (var i = 1; i < counts.length; i++) {
      expect(counts[i], greaterThanOrEqualTo(counts[i - 1]));
    }
    expect(counts.first, greaterThanOrEqualTo(60));
    expect(CompoundStructureData.forLevel('LEVEL_1_PRE').length, CompoundStructureData.all.length);
    expect(CompoundStructureData.forLevel('LEVEL_1').length, CompoundStructureData.all.length);
  });

  test('その級の演習には、その級より難しい字の語は出ない', () {
    final lv5 = LevelKanjiData.forLevel('LEVEL_5').toSet();
    final easy = <String>{for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6']) ...LevelKanjiData.forLevel(l)}..addAll(lv5);
    for (final q in CompoundStructureData.forLevel('LEVEL_5')) {
      expect(easy.containsAll(q.jukugo.split('')), isTrue, reason: q.jukugo);
    }
  });
}
