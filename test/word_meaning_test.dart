import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/word_meaning_data.dart';
import 'package:kanken/data/word_relation_data.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

void main() {
  test('準2級・2級の対義語・類義語の語は、すべて意味がある', () {
    final missing = <String>{};
    for (final r in kWordRelations) {
      if (r.level != 'LEVEL_2_PRE' && r.level != 'LEVEL_2') continue;
      for (final w in [r.word, r.partner]) {
        if (!kWordMeanings.containsKey(w)) missing.add(w);
      }
    }
    expect(missing, isEmpty);
  });

  test('意味は空でなく、1文(改行・タブなし)で、句点で終わる', () {
    for (final e in kWordMeanings.entries) {
      expect(e.value.trim(), isNotEmpty, reason: e.key);
      expect(e.value.contains('\n') || e.value.contains('\t'), isFalse, reason: e.key);
      expect(e.value.endsWith('。'), isTrue, reason: e.key);
    }
  });

  test('答え合わせの説明に、2語の意味が付く', () {
    final r = kWordRelations.firstWhere((r) => r.word == '肯定' && r.partner == '否定');
    final text = relationExplanation(r, WordRelationKind.antonym);
    final lines = text.split('\n');
    expect(lines.first, '肯定（こうてい）⇔否定（ひてい）');
    expect(lines.length, 3);
    expect(lines[1], startsWith('肯定：'));
    expect(lines[2], startsWith('否定：'));
  });

  test('意味が無い語だけの組は、1行のまま', () {
    final r = kWordRelations.firstWhere(
        (r) => !kWordMeanings.containsKey(r.word) && !kWordMeanings.containsKey(r.partner));
    expect(relationExplanation(r, r.kind).contains('\n'), isFalse);
  });
}
