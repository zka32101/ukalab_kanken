import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/theme/app_theme.dart';
import 'package:kanken/widgets/progress_visualization.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('連続学習カードは漢検の共通テーマ配色で、赤系の固定色を使わない（dark=$dark）', (tester) async {
      final theme = dark
          ? AppTheme.dark()
          : AppTheme.light();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: StreakWidget(streakDays: 5, lastActiveDate: DateTime.now()),
        ),
      ));
      final box = tester.widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .first;
      expect(box.color, theme.colorScheme.primaryContainer);

      // 文字(onPrimaryContainer)と面(primaryContainer)のコントラストが十分(4.5:1以上)。
      double lum(Color c) => c.computeLuminance();
      final a = lum(theme.colorScheme.onPrimaryContainer);
      final b = lum(theme.colorScheme.primaryContainer);
      final ratio = (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);
      expect(ratio, greaterThan(4.5));

      final days = tester.widget<Text>(find.text('5日間'));
      expect(days.style!.color, theme.colorScheme.onPrimaryContainer);
    });
  }
}
