import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/weak_area.dart';
import 'package:kanken/services/learning_plan_limits.dart';

WeakArea _area(String id, double rate) => WeakArea(
      categoryId: id,
      categoryName: id,
      totalAttempts: 10,
      correctAnswers: (10 * rate).round(),
      accuracyRate: rate,
      level: weakLevelFromAccuracy(rate),
      recentStreakDays: 0,
      lastAttemptAt: DateTime(2026, 10, 26),
    );

void main() {
  test('苦手な分野が多くても、正答率の低い順に3つまでにする', () {
    final targets = pickPlanTargets([
      for (var i = 0; i < 9; i++) _area('c$i', 0.05 * (i + 1)),
    ]);
    expect(targets.map((e) => e.categoryId), ['c0', 'c1', 'c2']);
  });

  test('分野が3つより少なければ、あるだけ返す', () {
    expect(pickPlanTargets([_area('a', 0.2)]).length, 1);
    expect(pickPlanTargets(const []), isEmpty);
  });

  test('1日の推奨問題数の合計は上限を超えない', () {
    final targets = pickPlanTargets([
      for (var i = 0; i < 9; i++) _area('c$i', 0.05 * (i + 1)),
    ]);
    final total = targets
        .map((a) => planDailyQuestions(a, targetCount: targets.length))
        .reduce((a, b) => a + b);
    expect(total, lessThanOrEqualTo(planDailyLimit));
  });

  test('分野が1つなら、その分野の推奨数をそのまま使う(上限の範囲で)', () {
    final a = _area('a', 0.1); // 25問が目安
    expect(planDailyQuestions(a, targetCount: 1), 25);
  });

  test('推奨数が分担分より少なければ、少ないほうを使う', () {
    final a = _area('a', 0.75); // 5問が目安
    expect(planDailyQuestions(a, targetCount: 3), 5);
  });

  test('対象が0件なら 0', () {
    expect(planDailyQuestions(_area('a', 0.1), targetCount: 0), 0);
  });
}
