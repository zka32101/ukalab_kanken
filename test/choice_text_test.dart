import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/widgets/choice_text.dart';

/// 選択肢の文字。1字（部首など）は、行の高さを固定して中央に置く。長い文字列は、これまでどおり。
void main() {
  test('1字だけの選択肢かどうか（サロゲートペアの字も1字）', () {
    expect(ChoiceText.isSingle('宀'), isTrue);
    expect(ChoiceText.isSingle('𠮟'), isTrue);
    expect(ChoiceText.isSingle('2画'), isFalse);
    expect(ChoiceText.isSingle('てへん'), isFalse);
    expect(ChoiceText.isSingle(''), isFalse);
  });

  testWidgets('1字は行の高さを固定して中央に置く・長い文字列は普通のTextのまま', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [ChoiceText('宀'), ChoiceText('てへん'), ChoiceText('A件　B建　C検')]),
      ),
    ));
    final single = tester.widget<Text>(find.text('宀'));
    expect(single.strutStyle?.forceStrutHeight, isTrue);
    expect(single.textAlign, TextAlign.center);
    for (final t in ['てへん', 'A件　B建　C検']) {
      expect(tester.widget<Text>(find.text(t)).strutStyle, isNull, reason: t);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('ボタンの中に置いても、オーバーフローしない（大きい文字でも）', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: Scaffold(
          body: Column(children: [
            for (final c in ['宀', '冖', '冂', '木', '10画'])
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, child: ChoiceText(c))),
          ]),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
