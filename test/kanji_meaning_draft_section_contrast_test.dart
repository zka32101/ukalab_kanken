import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/widgets/kanji_meaning_draft_section.dart';

void main() {
  testWidgets('意味の本文は、ダークテーマでは暗い色に固定されず、テーマの文字色で表示される', (tester) async {
    final theme = ThemeData.dark();
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const Scaffold(body: KanjiMeaningDraftSection(kanji: '一')),
    ));
    final body = tester.widget<Text>(find.text('数の1。'));
    expect(body.style?.color, theme.colorScheme.onSurface);
    expect(body.style?.color, isNot(Colors.black87));
  });
}
