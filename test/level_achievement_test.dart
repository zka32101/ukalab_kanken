import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/models/level_achievement.dart';
import 'package:kanken/providers/level_achievement_provider.dart';
import 'package:kanken/screens/level_hub_screen.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart';
import 'package:kanken/widgets/level_achievement_chips.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _id(String level, int i) =>
    '$level-${LevelKanjiData.forLevel(level)[i]}';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('questionStatCountsAsCorrect（一度でも正解したか）', () {
    test('everCorrect があれば正解済み（連続正解数が0に戻っていても）', () {
      expect(
          questionStatCountsAsCorrect(
              {'everCorrect': true, 'correctStreak': 0}),
          isTrue);
    });
    test('everCorrect が無い古い記録は、連続正解数が1以上なら正解済み', () {
      expect(questionStatCountsAsCorrect({'correctStreak': 1}), isTrue);
      expect(questionStatCountsAsCorrect({'correctStreak': 3}), isTrue);
    });
    test('連続正解数が0で everCorrect も無ければ、数えない', () {
      expect(questionStatCountsAsCorrect({'correctStreak': 0}), isFalse);
      expect(questionStatCountsAsCorrect({}), isFalse);
    });
  });

  group('LevelAchievement.compute', () {
    test('級ごとに、覚えた漢字と正解した漢字を、配当漢字に対する割合で出す', () {
      final total = LevelKanjiData.forLevel('LEVEL_10').length;
      final a = LevelAchievement.compute(
        levels: const ['LEVEL_10', 'LEVEL_9'],
        learnedIds: {_id('LEVEL_10', 0), _id('LEVEL_10', 1)},
        correctIds: {_id('LEVEL_10', 0), _id('LEVEL_9', 0)},
      );
      expect(a['LEVEL_10']!.totalKanji, total);
      expect(a['LEVEL_10']!.learnedKanji, 2);
      expect(a['LEVEL_10']!.correctKanji, 1);
      expect(a['LEVEL_10']!.learnedRate, closeTo(2 / total, 1e-9));
      expect(a['LEVEL_9']!.learnedKanji, 0);
      expect(a['LEVEL_9']!.correctKanji, 1);
    });

    test('同じIDを重ねて数えない（集合なので1つ）・配当に無い漢字や別の級のIDは数えない', () {
      final a = LevelAchievement.compute(
        levels: const ['LEVEL_10'],
        learnedIds: {_id('LEVEL_10', 0), 'LEVEL_10-〓', _id('LEVEL_9', 0), 'ゴミ'},
        correctIds: const {},
      );
      expect(a['LEVEL_10']!.learnedKanji, 1);
    });

    test('全部を満たしても100%を超えない', () {
      final all = {
        for (var i = 0; i < LevelKanjiData.forLevel('LEVEL_10').length; i++)
          _id('LEVEL_10', i)
      };
      final a = LevelAchievement.compute(
          levels: const ['LEVEL_10'],
          learnedIds: all,
          correctIds: all)['LEVEL_10']!;
      expect(a.learnedRate, 1.0);
      expect(a.correctRate, 1.0);
    });

    test('問題が用意されている級は 10級〜3級だけ', () {
      final a = LevelAchievement.compute(
          levels: kKankenLevels, learnedIds: const {}, correctIds: const {});
      for (final l in ['LEVEL_10', 'LEVEL_5', 'LEVEL_3']) {
        expect(a[l]!.hasQuestions, isTrue, reason: l);
      }
      for (final l in ['LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1']) {
        expect(a[l]!.hasQuestions, isFalse, reason: l);
      }
    });
  });

  group('LevelColors（割合を彩度で表す）', () {
    test('0%は灰色（彩度0）、100%は鮮やか（彩度1）', () {
      expect(HSVColor.fromColor(LevelColors.of('LEVEL_10', 0)).saturation,
          closeTo(0, 0.01));
      expect(HSVColor.fromColor(LevelColors.of('LEVEL_10', 1)).saturation,
          closeTo(1, 0.01));
    });
    test('割合が上がるほど、彩度が上がる', () {
      var prev = -1.0;
      for (final r in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final s = HSVColor.fromColor(LevelColors.of('LEVEL_7', r)).saturation;
        expect(s, greaterThanOrEqualTo(prev));
        prev = s;
      }
    });
    test('級ごとに色相が違う（12級ぶん）', () {
      final hues = {for (final l in kKankenLevels) LevelColors.hueOf(l)};
      expect(hues.length, kKankenLevels.length);
    });
    test('範囲外の割合は、0〜1に収める', () {
      expect(LevelColors.of('LEVEL_10', -1), LevelColors.of('LEVEL_10', 0));
      expect(LevelColors.of('LEVEL_10', 2), LevelColors.of('LEVEL_10', 1));
    });
  });

  group('LevelAchievementChips', () {
    Widget app(LevelAchievement a) => MaterialApp(
        home: Scaffold(body: LevelAchievementChips(achievement: a)));

    testWidgets('漢字と問題の割合を、数字で出す', (tester) async {
      const a = LevelAchievement(
          level: 'LEVEL_10',
          totalKanji: 80,
          learnedKanji: 36,
          correctKanji: 24,
          hasQuestions: true);
      await tester.pumpWidget(app(a));
      expect(find.text('漢字 45%'), findsOneWidget);
      expect(find.text('問題 30%'), findsOneWidget);
    });

    testWidgets('問題が無い級は「問題 準備中」', (tester) async {
      const a = LevelAchievement(
          level: 'LEVEL_2',
          totalKanji: 185,
          learnedKanji: 0,
          correctKanji: 0,
          hasQuestions: false);
      await tester.pumpWidget(app(a));
      expect(find.text('漢字 0%'), findsOneWidget);
      expect(find.text('問題 準備中'), findsOneWidget);
    });

    testWidgets('読み上げ用の文言に、割合が入る', (tester) async {
      const a = LevelAchievement(
          level: 'LEVEL_10',
          totalKanji: 80,
          learnedKanji: 36,
          correctKanji: 24,
          hasQuestions: true);
      expect(LevelAchievementChips.semanticsLabel(a), '漢字 45パーセント、問題 30パーセント');
    });
  });

  testWidgets('級の画面に、達成度の2つの印が出る（学習済み・正解済みの漢字が反映される）', (tester) async {
    final c = ProviderContainer(overrides: [
      levelAchievementProvider.overrideWith((ref) => LevelAchievement.compute(
            levels: kKankenLevels,
            learnedIds: {_id('LEVEL_8', 0), _id('LEVEL_8', 1)},
            correctIds: {_id('LEVEL_8', 0)},
          )),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: LevelHubScreen(level: 'LEVEL_8')),
    ));
    await tester.pump();
    final total = LevelKanjiData.forLevel('LEVEL_8').length;
    expect(find.text('漢字 ${LevelAchievement.percent(2 / total)}%'),
        findsOneWidget);
    expect(find.text('問題 ${LevelAchievement.percent(1 / total)}%'),
        findsOneWidget);
    expect(c.read(currentLevelProvider), isNotEmpty);
  });
}
