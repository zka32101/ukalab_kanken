import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanken_data_parts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> make() async {
    final overrides = [
      ...await studyNotesOverrides('kanken'),
      ...await dailyGoalOverrides('kanken'),
    ];
    return ProviderContainer(overrides: overrides);
  }

  testWidgets('書き出し→リセット→読み込みで、目標とメモが元に戻る', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final c = await make();
    addTearDown(c.dispose);
    late WidgetRef ref;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const SizedBox();
      }),
    ));

    await c.read(dailyGoalProvider.notifier).setTarget(20);
    await c.read(questionMemoProvider.notifier).setMemo(qid: 'q1', memo: 'おぼえる');

    final backup = await encodeLearningDataBackupAsync(ref, kankenDataParts);
    expect(backup, contains('questionMemo'));

    await resetLearningData(ref, kankenDataParts);
    expect(c.read(dailyGoalProvider).target, isNull);
    expect(c.read(questionMemoProvider), isEmpty);

    await restoreLearningDataBackup(ref, kankenDataParts, backup);
    expect(c.read(dailyGoalProvider).target, 20);
    expect(c.read(questionMemoProvider)['q1'], 'おぼえる');
  });

  testWidgets('壊れたバックアップは FormatException で拒否する', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final c = await make();
    addTearDown(c.dispose);
    late WidgetRef ref;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const SizedBox();
      }),
    ));
    expect(
      () => restoreLearningDataBackup(ref, kankenDataParts, 'not json'),
      throwsFormatException,
    );
  });
}
