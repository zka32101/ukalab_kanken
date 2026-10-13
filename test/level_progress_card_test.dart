import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/level_progress.dart';
import 'package:kanken/widgets/level_progress_card.dart';

/// 問題が1問も無い級では、「0 / 0」「あと20問正解で次の級へ！」を出さない。
void main() {
  const empty = LevelProgress(level: 'pre2', correctCount: 0, totalCount: 0);

  Future<void> pump(WidgetTester tester, {required bool noQuestions}) =>
      tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LevelProgressCard(
            levelLabel: '準2級（高校在学程度）',
            progress: empty,
            noQuestions: noQuestions,
          ),
        ),
      ));

  testWidgets('問題が無い級は準備中の案内を出し、進捗や次の級の案内を出さない', (tester) async {
    await pump(tester, noQuestions: true);

    expect(find.text('準2級（高校在学程度）'), findsOneWidget);
    expect(find.text('この級の問題は、準備中です'), findsOneWidget);
    expect(find.textContaining('次の級へ'), findsNothing);
    expect(find.text('0 / 0'), findsNothing);
  });

  testWidgets('問題がある級（まだ解いていない）は、これまでどおり進捗と次の級の案内を出す', (tester) async {
    await pump(tester, noQuestions: false);

    expect(find.text('あと20問正解で次の級へ！'), findsOneWidget);
    expect(find.text('この級の問題は、準備中です'), findsNothing);
  });
}
