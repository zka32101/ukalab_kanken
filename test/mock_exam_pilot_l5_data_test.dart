import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_stroke_count_data.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/models/mock_exam_modes.dart';

/// 5級の模擬試験パイロット増量分（scripts/data/exam-questions-pilot-l5.json）の回帰テスト。
/// 詳しい機械検証は `node scripts/verify-exam-questions-pilot.js 5`。
void main() {
  final data = (jsonDecode(
    File('scripts/data/exam-questions-pilot-l5.json').readAsStringSync(),
  ) as List)
      .cast<Map<String, dynamic>>();
  final level5 = LevelKanjiData.forLevel('LEVEL_5').toSet();

  test('90問（読み40・書き取り30・画数20）で、IDが重複しない', () {
    expect(data.length, 90);
    for (final e in {'reading': 40, 'writing': 30, 'stroke': 20}.entries) {
      expect(data.where((q) => q['questionType'] == e.key).length, e.value);
    }
    expect(data.map((q) => q['questionId']).toSet().length, 90);
  });

  test('EnhancedExamQuestion で読め、選択肢は4つ・重複なし・正解を含む', () {
    for (final q in data) {
      final p = EnhancedExamQuestion.fromJson(q);
      expect(p.level, 5);
      expect(p.options.length, 4);
      expect(p.options.toSet().length, 4, reason: p.questionId);
      expect(p.options, contains(p.correctAnswer));
      expect(q['category'], 'ExamCategory.${q['questionType']}');
    }
  });

  test('対象漢字は5級の配当内で、同じカテゴリ内で字が重複しない', () {
    final seen = <String>{};
    for (final q in data) {
      expect(level5, contains(q['kanji']), reason: q['questionId'] as String);
      expect(seen.add('${q['questionType']}:${q['kanji']}'), isTrue);
    }
  });

  test('画数の正解は画数データと一致する', () {
    for (final q in data.where((q) => q['questionType'] == 'stroke')) {
      expect(q['correctAnswer'], '${kanjiStrokeCount(q['kanji'] as String)}画');
    }
  });

  test('正解の位置が偏らない', () {
    final pos = List.filled(4, 0);
    for (final q in data) {
      pos[(q['options'] as List).indexOf(q['correctAnswer'])]++;
    }
    for (final c in pos) {
      expect(c, inInclusiveRange(18, 27), reason: '$pos');
    }
  });

  test('書き取りの問題文に答えの漢字が含まれない', () {
    for (final q in data.where((q) => q['questionType'] == 'writing')) {
      expect(q['question'], isNot(contains(q['correctAnswer'])));
    }
  });
}
