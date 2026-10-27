import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/screens/content_counts_screen.dart';
import 'package:kanken/services/content_counts.dart';

void main() {
  test('級は10級から1級まで12級ぶん、やさしい順に並ぶ', () {
    final rows = buildContentCounts();
    expect(rows.map((r) => r.level).toList(), kContentCountLevels);
    expect(rows.length, 12);
  });

  test('配当漢字の数は、各級にある(10級=80字、2級=185字)', () {
    final byLevel = {for (final r in buildContentCounts()) r.level: r};
    expect(byLevel['LEVEL_10']!.kanjiCount, 80);
    expect(byLevel['LEVEL_2']!.kanjiCount, 185);
    expect(byLevel['LEVEL_2_PRE']!.kanjiCount, 328);
  });

  test('上の級ほど、出せる問題の合計が増える(5級→3級→準2級)', () {
    final byLevel = {for (final r in buildContentCounts()) r.level: r.total};
    expect(byLevel['LEVEL_3']!, greaterThan(byLevel['LEVEL_5']!));
    expect(byLevel['LEVEL_2_PRE']!, greaterThan(byLevel['LEVEL_3']!));
  });

  test('分野名は日本語で、英語の内部名が出ない', () {
    for (final r in buildContentCounts()) {
      for (final name in r.counts.keys) {
        expect(RegExp(r'[A-Za-z]').hasMatch(name), isFalse, reason: '${r.level}: $name');
      }
      for (final n in r.counts.values) {
        expect(n, greaterThan(0));
      }
    }
  });

  testWidgets('画面に、各級のカードと「問」の数が出る', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ContentCountsScreen()));
    expect(find.text('収録問題数'), findsOneWidget);
    expect(find.byKey(const ValueKey('contentCounts_LEVEL_10')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('contentCounts_LEVEL_2_PRE')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('contentCounts_LEVEL_2_PRE')), findsOneWidget);
    expect(find.textContaining('問'), findsWidgets);
  });
}
