import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/chapter_readings.dart';
import 'package:ukalab_core/ukalab_core.dart'
    show parseChapterReadingsJsonl, validateChapterReadings;

/// 解説読み物（JSONL）の機械検証。配信前の品質ゲート。
void main() {
  final parsed = parseChapterReadingsJsonl(
    File(kChapterReadingsAsset).readAsStringSync(),
  );

  test('読み込めて、core の品質ゲートを通る', () {
    expect(parsed.issues, isEmpty, reason: '${parsed.issues}');
    expect(parsed.items.length, greaterThanOrEqualTo(10));
    final issues = validateChapterReadings(parsed.items);
    expect(issues, isEmpty, reason: '$issues');
  });

  test('readingId が重複せず、区分が定義済みで、自作の文章である', () {
    final ids = [for (final r in parsed.items) r.readingId];
    expect(ids.toSet().length, ids.length);
    final groupIds = {for (final g in kReadingGroups) g.id};
    for (final r in parsed.items) {
      expect(groupIds, contains(r.subjectId), reason: r.readingId);
      expect(r.examId, 'kanken');
      expect(r.source.name, 'original', reason: r.readingId);
    }
    // どの区分にも1本以上ある
    for (final g in kReadingGroups) {
      expect(parsed.items.where((r) => r.subjectId == g.id), isNotEmpty,
          reason: g.id);
    }
  });

  test('1本あたり1,500字以上・節が4つ以上で、同じ文の使い回しがない', () {
    final seen = <String>{};
    for (final r in parsed.items) {
      final total = r.sections.fold<int>(0, (n, s) => n + s.body.length);
      expect(total, greaterThanOrEqualTo(1500), reason: r.readingId);
      expect(r.sections.length, greaterThanOrEqualTo(4), reason: r.readingId);
      for (final s in r.sections) {
        for (final sentence in s.body.split('。')) {
          if (sentence.length < 20) continue;
          expect(seen.add(sentence), isTrue,
              reason: '${r.readingId}: 文が重複しています: $sentence');
        }
      }
    }
  });

  test('pubspec にアセットが登録されている', () {
    expect(File('pubspec.yaml').readAsStringSync(),
        contains('- assets/readings/'));
  });
}
