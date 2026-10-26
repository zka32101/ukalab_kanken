import '../models/weak_area.dart';

/// 学習推奨プランに入れる分野の数。苦手な分野を全部並べると、
/// 1日にこなせない量になるので、正答率の低い順にこの数までにする。
const planMaxItems = 3;

/// 1日に勧める問題数の合計の上限。
const planDailyLimit = 30;

/// プランの対象にする分野。正答率の低い順に [planMaxItems] 件。
List<WeakArea> pickPlanTargets(List<WeakArea> weakAreas) {
  final sorted = [...weakAreas]
    ..sort((a, b) => a.accuracyRate.compareTo(b.accuracyRate));
  return sorted.take(planMaxItems).toList();
}

/// 分野ごとの1日の推奨問題数。合計が [planDailyLimit] を超えないように、
/// 対象の分野数で割った数を上限にする。
int planDailyQuestions(WeakArea area, {required int targetCount}) {
  if (targetCount <= 0) return 0;
  final share = planDailyLimit ~/ targetCount;
  final wanted = area.getRecommendedQuestionCount();
  return wanted < share ? wanted : share;
}
