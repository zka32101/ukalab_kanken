import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_meaning_draft_data.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/widgets/kanji_meaning_draft_section.dart';

/// 漢字の意味(AI下書き)の検査。意味は AI が書いた未確認の下書き。
void main() {
  const levels = [
    'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', //
    'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2',
  ];
  const expectedPerLevel = {
    'LEVEL_10': 80, 'LEVEL_9': 160, 'LEVEL_8': 200, 'LEVEL_7': 202, 'LEVEL_6': 193, 'LEVEL_5': 191,
    'LEVEL_4': 313, 'LEVEL_3': 284, 'LEVEL_2_PRE': 328, 'LEVEL_2': 185,
  };
  final target = [for (final l in levels) ...LevelKanjiData.forLevel(l)];

  final blank = <String>{};
  final row = RegExp(r'^\| (?:\d+|準2) \| (\S) \| ');
  var inBlank = false;
  for (final line in File('docs/data_verification/meaning_review.md').readAsLinesSync()) {
    if (line.startsWith('## ')) inBlank = line.contains('意味なし');
    final m = row.firstMatch(line);
    if (inBlank && m != null) blank.add(m.group(1)!);
  }

  test('対象は10級〜2級(準2級を含む)の2,136字で、級別の字数が合う', () {
    expect(target.length, 2136);
    expect(target.toSet().length, 2136);
    for (final e in expectedPerLevel.entries) {
      expect(LevelKanjiData.forLevel(e.key).length, e.value, reason: e.key);
    }
  });

  test('4級〜2級の字には、意味または空欄の登録がある(4級313・3級284・準2級328・2級185)', () {
    for (final l in ['LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) {
      for (final k in LevelKanjiData.forLevel(l)) {
        expect(kKanjiMeaningDraft.containsKey(k) || blank.contains(k), isTrue, reason: '$l $k');
      }
    }
  });

  test('入っている字はすべて10〜2級の字で、重複なし', () {
    expect(kKanjiMeaningDraft.keys.toSet().difference(target.toSet()), isEmpty);
    // Map リテラルの重複キーはコンパイル時に弾かれるが、件数も確認する。
    expect(kKanjiMeaningDraft.length, kKanjiMeaningDraft.keys.toSet().length);
  });

  test('意味を入れた字 + 空欄(要確認一覧) = 2,136字で、重なりなし', () {
    expect(blank, isNotEmpty);
    expect(blank.intersection(kKanjiMeaningDraft.keys.toSet()), isEmpty);
    expect(kKanjiMeaningDraft.length + blank.length, 2136);
    expect(target.toSet().difference({...kKanjiMeaningDraft.keys, ...blank}), isEmpty);
  });

  test('意味は空文字でなく、1〜2文以内(短い)', () {
    for (final e in kKanjiMeaningDraft.entries) {
      final m = e.value.meaning;
      expect(m.trim(), isNotEmpty, reason: e.key);
      expect(m.length <= 40, isTrue, reason: '${e.key}: $m');
      expect('。'.allMatches(m).length <= 3, isTrue, reason: '${e.key}: $m');
    }
  });

  test('参照APIと reviewStatus', () {
    expect(kanjiMeaningDraft('山'), isNotNull);
    expect(kanjiMeaningDraft('奈'), isNull);
    expect(kanjiMeaningDraft('龍'), isNull);
    expect(kanjiMeaningDraftEntry('山')!.reviewStatus, KanjiMeaningReviewStatus.draft);
    expect(
      kKanjiMeaningDraft.values.any((v) => v.reviewStatus == KanjiMeaningReviewStatus.needsReview),
      isTrue,
    );
  });

  test('表示フラグの既定は false', () {
    expect(kKanjiMeaningVisible, isFalse);
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('既定(フラグ false)では何も表示しない', (tester) async {
    await tester.pumpWidget(host(const KanjiMeaningDraftSection(kanji: '山')));
    expect(find.textContaining('AI下書き'), findsNothing);
  });

  testWidgets('visible: true のときだけ「AI下書き・未確認」付きで表示', (tester) async {
    await tester.pumpWidget(host(const KanjiMeaningDraftSection(kanji: '山', visible: true)));
    expect(find.text('意味（AI下書き・未確認）'), findsOneWidget);
    expect(find.text(kanjiMeaningDraft('山')!), findsOneWidget);
  });

  testWidgets('下書きが無い字は visible: true でも何も出さない', (tester) async {
    await tester.pumpWidget(host(const KanjiMeaningDraftSection(kanji: '奈', visible: true)));
    expect(find.textContaining('AI下書き'), findsNothing);
  });
}
