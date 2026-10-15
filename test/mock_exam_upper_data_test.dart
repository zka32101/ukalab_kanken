import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/mock_exam_modes.dart';

/// 4級・3級・準2級・2級の模擬試験問題データ（scripts/data/exam-questions-upper.json）の
/// 形式と、画面側の級→examQuestions の level 対応を確かめる回帰テスト。
void main() {
  final file = File('scripts/data/exam-questions-upper.json');
  final data = (jsonDecode(file.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  // 級 -> examQuestions の level（mock_exam_modes_screen.dart の変換と同じ）
  const levels = {'4級': 4, '3級': 3, '準2級': 25, '2級': 2};

  for (final e in levels.entries) {
    group('${e.key}（level=${e.value}）', () {
      final qs = data.where((q) => q['level'] == e.value).toList();

      test('20問（読み10・書き取り10）で、IDが重複しない', () {
        expect(qs.length, 20);
        expect(qs.where((q) => q['category'] == 'ExamCategory.reading').length, 10);
        expect(qs.where((q) => q['category'] == 'ExamCategory.writing').length, 10);
        expect(qs.map((q) => q['questionId']).toSet().length, 20);
        for (final q in qs) {
          expect(q['questionId'], startsWith('l${e.value}-'));
        }
      });

      test('すべて EnhancedExamQuestion.fromJson で読め、選択肢は4つで正解を含む', () {
        for (final q in qs) {
          final parsed = EnhancedExamQuestion.fromJson(q);
          expect(parsed.level, e.value);
          expect(parsed.options.length, 4);
          expect(parsed.options.toSet().length, 4, reason: q['questionId'] as String);
          expect(parsed.options, contains(parsed.correctAnswer));
        }
      });

      test('正解の位置が偏らない', () {
        final pos = List.filled(4, 0);
        for (final q in qs) {
          pos[(q['options'] as List).indexOf(q['correctAnswer'])]++;
        }
        for (final c in pos) {
          expect(c, inInclusiveRange(3, 7), reason: '$pos');
        }
      });

      test('書き取りの問題文に答えの漢字が含まれない（答え漏れ防止）', () {
        for (final q in qs.where((q) => q['category'] == 'ExamCategory.writing')) {
          expect(q['question'], isNot(contains(q['correctAnswer'])),
              reason: q['questionId'] as String);
        }
      });
    });
  }

  test('模擬試験の level 対応: 準2級(25)は60分・70%、準1級(15)は60分・80%', () {
    expect(ExamConfig.standard(level: 25).timeLimit, 60);
    expect(ExamConfig.standard(level: 25).passThreshold, 70);
    expect(ExamConfig.standard(level: 15).timeLimit, 60);
    expect(ExamConfig.standard(level: 15).passThreshold, 80);
    expect(ExamConfig.standard(level: 4).targetLevel, 4);
  });
}
