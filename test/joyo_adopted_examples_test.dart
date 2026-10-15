import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_info_data.dart';

/// 常用漢字表(平成22年内閣告示)の「例」から追加した用例の検査。
/// scripts/data/joyo_adopted_examples.tsv は scripts/check_joyo_official.py が
/// 抽出データとの突合(語が表の例にあること)を済ませて出力したもの。
void main() {
  final rows = <List<String>>[];
  for (final line in File('scripts/data/joyo_adopted_examples.tsv').readAsLinesSync()) {
    if (line.startsWith('#') || line.trim().isEmpty) continue;
    rows.add(line.split('\t'));
  }

  test('追加語の一覧が空でなく、列が揃っている', () {
    expect(rows, isNotEmpty);
    for (final r in rows) {
      expect(r.length, 6, reason: r.join('|'));
      for (final c in r) {
        expect(c.trim(), isNotEmpty, reason: r.join('|'));
      }
    }
  });

  test('追加語は一覧どおり「語（よみ）」で用例に入り、見出し字を含み、重複しない', () {
    final seen = <String>{};
    for (final r in rows) {
      final kanji = r[0], word = r[3], yomi = r[4];
      expect(word.contains(kanji), isTrue, reason: '$kanji: $word');
      expect(seen.add('$kanji:$word'), isTrue, reason: '一覧内で重複 $kanji:$word');
      final info = KanjiInfoData.get(kanji)!;
      final entry = '$word（$yomi）';
      expect(info.examples.where((e) => e == entry).length, 1, reason: '$kanji: $entry');
      expect(info.examples.toSet().length, info.examples.length, reason: '$kanji: 用例の重複');
      expect(info.examples.every((e) => e.trim().isNotEmpty), isTrue, reason: kanji);
    }
  });

  test('追加語に読みの対応が付いている(読みがアプリの readings にある)', () {
    for (final r in rows) {
      final info = KanjiInfoData.get(r[0])!;
      expect(info.readings, contains(r[2]), reason: r.join('|'));
    }
  });
}
