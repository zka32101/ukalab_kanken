import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/level_kanji_data.dart';

/// 級別配当漢字と、問題データ(scripts/seed-kanji-questions.js)の検査。
///
/// 10級〜5級は小学校の「学年別漢字配当表」(学習指導要領の別表、文部科学省告示・
/// 2017年告示)と一致する。照合用の表は test/fixtures/official_grades.json
/// (第1〜6学年 = 10級〜5級)。
void main() {
  final official = (jsonDecode(File('test/fixtures/official_grades.json').readAsStringSync())
          as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, (v as String).split('')));
  const gradeOf = {
    'LEVEL_10': '1',
    'LEVEL_9': '2',
    'LEVEL_8': '3',
    'LEVEL_7': '4',
    'LEVEL_6': '5',
    'LEVEL_5': '6',
  };

  group('級別配当漢字', () {
    test('10級〜5級は学年別漢字配当表と過不足なく一致(計1,026字)', () {
      var total = 0;
      gradeOf.forEach((level, grade) {
        final mine = LevelKanjiData.forLevel(level);
        final expected = official[grade]!;
        expect(mine.toSet(), expected.toSet(), reason: level);
        expect(mine.length, expected.length, reason: '$level に重複');
        total += mine.length;
      });
      expect(total, 1026);
    });

    test('4級313字・3級284字。小学校の配当漢字や、他の級と重複しない', () {
      final edu = official.values.expand((e) => e).toSet();
      final l4 = LevelKanjiData.forLevel('LEVEL_4');
      final l3 = LevelKanjiData.forLevel('LEVEL_3');
      expect(l4.length, 313);
      expect(l3.length, 284);
      expect(l4.toSet().length, l4.length);
      expect(l3.toSet().length, l3.length);
      expect(l4.toSet().intersection(edu), isEmpty, reason: '2020年から小学校配当になった字は除く');
      expect(l3.toSet().intersection(edu), isEmpty);
      expect(l4.toSet().intersection(l3.toSet()), isEmpty);
    });
  });

  group('準2級・2級(常用漢字表の残り513字・振り分けは要照合)', () {
    test('準2級328字・2級185字。3級までの1,623字と重複せず、合わせて常用漢字2,136字', () {
      final lower = [
        for (final l in [...gradeOf.keys, 'LEVEL_4', 'LEVEL_3']) ...LevelKanjiData.forLevel(l),
      ];
      final pre = LevelKanjiData.forLevel('LEVEL_2_PRE');
      final l2 = LevelKanjiData.forLevel('LEVEL_2');
      expect(pre.length, 328);
      expect(l2.length, 185);
      expect(lower.length, 1623);
      final all = [...lower, ...pre, ...l2];
      expect(all.toSet().length, all.length, reason: '級をまたいだ重複');
      expect(all.length, 2136);
    });

    test('級別漢字表(2020年2月発表)で2級配当の字が準2級に入っていない', () {
      // 公式 https://www.kanken.or.jp/kanken/outline/data/outline_degree_national_list20200217.pdf の2級(185字)に載る字
      const l2Only = '嵐咽怨牙瓦潰崖蓋柿釜鎌韓亀嗅僅憬隙桁拳鍵股虎喉駒頃痕餌嫉袖拭尻芯腎戚腺狙';
      final pre = LevelKanjiData.forLevel('LEVEL_2_PRE').toSet();
      final l2 = LevelKanjiData.forLevel('LEVEL_2').toSet();
      for (final c in l2Only.split('')) {
        expect(l2.contains(c), isTrue, reason: '$c は2級配当');
        expect(pre.contains(c), isFalse, reason: '$c は準2級ではない');
      }
      // 公式の準2級に載る字の例
      for (final c in '且丙俸劾唆嗣嚇塑奔娠嫡'.split('')) {
        expect(pre.contains(c), isTrue, reason: '$c は準2級配当');
      }
    });
  });

  group('準1級(941字・要照合)', () {
    test('941字。常用漢字2,136字と重複しない', () {
      final joyo = [
        for (final l in [...gradeOf.keys, 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2'])
          ...LevelKanjiData.forLevel(l),
      ];
      final pre1 = LevelKanjiData.forLevel('LEVEL_1_PRE');
      expect(joyo.length, 2136);
      expect(pre1.length, 941);
      expect(pre1.toSet().length, pre1.length, reason: '準1級内の重複');
      expect(pre1.toSet().intersection(joyo.toSet()), isEmpty);
    });
  });

  group('1級(2,797字・要照合)', () {
    test('2,797字。準1級までの5,213字(常用+準1級)と重複しない', () {
      final lower = [
        for (final l in [...gradeOf.keys, 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE'])
          ...LevelKanjiData.forLevel(l),
      ];
      final l1 = LevelKanjiData.forLevel('LEVEL_1');
      expect(lower.length, 3077);
      expect(l1.length, 2797);
      expect(l1.toSet().length, l1.length, reason: '1級内の重複');
      expect(l1.toSet().intersection(lower.toSet()), isEmpty);
    });
  });

  group('問題データ(シード)', () {
    final js = File('scripts/seed-kanji-questions.js').readAsStringSync();
    final start = js.indexOf('const questions = [') + 'const questions = '.length;
    final end = js.indexOf('\n];', start) + 2;
    final body = js.substring(start, end).trim().replaceFirst(RegExp(r',\s*\]$'), ']');
    final qs = (jsonDecode(body) as List).cast<Map<String, dynamic>>();

    test('級ごとの問題数が配当漢字の数と一致し、重複がない', () {
      final ids = qs.map((q) => q['id'] as String).toList();
      expect(ids.toSet().length, ids.length);
      for (final level in [...gradeOf.keys, 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1']) {
        final inLevel = qs.where((q) => q['level'] == level).toList();
        final kanji = LevelKanjiData.forLevel(level);
        expect(inLevel.map((q) => q['kanji']).toSet(), kanji.toSet(), reason: level);
        expect(inLevel.length, kanji.length, reason: level);
      }
    });

    test('選択肢は4つ・重複なし・正解を含み、同じ級の字だけ', () {
      for (final q in qs) {
        final choices = (q['choices'] as List).cast<String>();
        final level = q['level'] as String;
        final kanji = LevelKanjiData.forLevel(level).toSet();
        expect(choices.length, 4, reason: q['id']);
        expect(choices.toSet().length, 4, reason: q['id']);
        expect(choices, contains(q['correctAnswer']), reason: q['id']);
        expect(q['correctAnswer'], q['kanji'], reason: q['id']);
        for (final c in choices) {
          expect(kanji, contains(c), reason: '${q['id']} の選択肢 $c');
        }
      }
    });

    test('用例に見出しの字が含まれる', () {
      for (final q in qs) {
        final e = q['example'] as String?;
        if (e == null || e.isEmpty) continue;
        expect(e, contains(q['kanji'] as String), reason: q['id']);
      }
    });

    test('常用漢字表にない読みを入れていない(確認済みの誤り: 薪=まき)', () {
      final q = qs.firstWhere((q) => q['id'] == 'LEVEL_4-薪');
      expect(q['reading'], 'たきぎ');
    });
  });
}
