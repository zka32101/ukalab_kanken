import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exam_analysis_provider.dart';

/// 学習計画アイテム
class LearningPlanItem {
  final String id;
  final String category;
  final int priority; // 1 = 最優先
  final int recommendedDaysPerWeek;
  final int recommendedMinutesPerSession;
  final String description;
  final DateTime createdAt;

  const LearningPlanItem({
    required this.id,
    required this.category,
    required this.priority,
    required this.recommendedDaysPerWeek,
    required this.recommendedMinutesPerSession,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'priority': priority,
    'recommendedDaysPerWeek': recommendedDaysPerWeek,
    'recommendedMinutesPerSession': recommendedMinutesPerSession,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// 週間学習スケジュール
class WeeklySchedule {
  final List<LearningPlanItem> schedule;
  final int totalMinutesPerWeek;
  final DateTime weekStartDate;
  final String focusArea;

  const WeeklySchedule({
    required this.schedule,
    required this.totalMinutesPerWeek,
    required this.weekStartDate,
    required this.focusArea,
  });

  Map<String, dynamic> toJson() => {
    'schedule': schedule.map((s) => s.toJson()).toList(),
    'totalMinutesPerWeek': totalMinutesPerWeek,
    'weekStartDate': weekStartDate.toIso8601String(),
    'focusArea': focusArea,
  };
}

/// 学習計画全体
class LearningPlan {
  final String userId;
  final List<LearningPlanItem> prioritizedItems;
  final WeeklySchedule currentWeekSchedule;
  final List<WeeklySchedule> nextWeeksSchedules;
  final DateTime generatedAt;
  final String overallStrategy;

  const LearningPlan({
    required this.userId,
    required this.prioritizedItems,
    required this.currentWeekSchedule,
    required this.nextWeeksSchedules,
    required this.generatedAt,
    required this.overallStrategy,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'prioritizedItems': prioritizedItems.map((i) => i.toJson()).toList(),
    'currentWeekSchedule': currentWeekSchedule.toJson(),
    'nextWeeksSchedules': nextWeeksSchedules.map((s) => s.toJson()).toList(),
    'generatedAt': generatedAt.toIso8601String(),
    'overallStrategy': overallStrategy,
  };
}

/// 弱点分析から学習計画を生成するプロバイダー
final learningPlanGeneratorProvider = FutureProvider<LearningPlan?>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;

  try {
    final history = await ref.watch(userWeakPointHistoryProvider.future);
    if (history.isEmpty) return null;

    final latestAnalysis = history.first;
    return await _generateLearningPlan(userId, latestAnalysis);
  } catch (e) {
    return null;
  }
});

/// ユーザーの保存済み学習計画を取得
final userLearningPlanProvider = FutureProvider<LearningPlan?>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('learningPlans')
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .get();

    if (doc.docs.isEmpty) return null;

    final data = doc.docs.first.data();
    return _parseLearningPlan(data);
  } catch (e) {
    return null;
  }
});

/// 学習進捗を取得
final learningProgressProvider = FutureProvider.family<double, String>((ref, category) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return 0.0;

  try {
    final accumulated = await ref.watch(accumulatedCategoryPerformanceProvider.future);
    final performance = accumulated[category];

    if (performance == null) return 0.0;

    return performance.accuracy.clamp(0.0, 1.0);
  } catch (e) {
    return 0.0;
  }
});

/// 学習計画を生成
Future<LearningPlan> _generateLearningPlan(
  String userId,
  ExamAnalysisResult latestAnalysis,
) async {
  // 優先度順にソート
  final sortedWeakPoints = [...latestAnalysis.weakPoints];
  sortedWeakPoints.sort((a, b) => a.priority.compareTo(b.priority));

  // LearningPlanItemを作成
  final prioritizedItems = <LearningPlanItem>[];
  for (int i = 0; i < sortedWeakPoints.length; i++) {
    final weakPoint = sortedWeakPoints[i];

    // 正答率が低いほど学習時間を増やす
    final minutesPerSession = weakPoint.accuracy < 0.4
        ? 30
        : weakPoint.accuracy < 0.6
            ? 25
            : 20;

    final daysPerWeek = weakPoint.priority == 1
        ? 5
        : weakPoint.priority == 2
            ? 3
            : 2;

    prioritizedItems.add(
      LearningPlanItem(
        id: 'plan_${DateTime.now().millisecondsSinceEpoch}_$i',
        category: weakPoint.category,
        priority: weakPoint.priority,
        recommendedDaysPerWeek: daysPerWeek,
        recommendedMinutesPerSession: minutesPerSession,
        description: weakPoint.recommendation,
        createdAt: DateTime.now(),
      ),
    );
  }

  // 週間スケジュールを生成
  final currentWeekSchedule = _generateWeeklySchedule(prioritizedItems, 0);
  final nextWeeksSchedules = [
    _generateWeeklySchedule(prioritizedItems, 1),
    _generateWeeklySchedule(prioritizedItems, 2),
    _generateWeeklySchedule(prioritizedItems, 3),
  ];

  // 全体戦略を決定
  final overallStrategy = _determineStrategy(latestAnalysis, sortedWeakPoints);

  return LearningPlan(
    userId: userId,
    prioritizedItems: prioritizedItems,
    currentWeekSchedule: currentWeekSchedule,
    nextWeeksSchedules: nextWeeksSchedules,
    generatedAt: DateTime.now(),
    overallStrategy: overallStrategy,
  );
}

/// 週間スケジュールを生成
WeeklySchedule _generateWeeklySchedule(
  List<LearningPlanItem> items,
  int weekOffset,
) {
  final weekStart = DateTime.now().add(Duration(days: weekOffset * 7));

  // 優先度順に項目を配置
  final schedule = <LearningPlanItem>[];
  int totalMinutes = 0;

  for (final item in items) {
    schedule.add(item);
    totalMinutes += item.recommendedMinutesPerSession * item.recommendedDaysPerWeek;
  }

  // 最初の週の焦点エリアを決定
  final focusArea = items.isNotEmpty ? items.first.category : '総合';

  return WeeklySchedule(
    schedule: schedule,
    totalMinutesPerWeek: totalMinutes,
    weekStartDate: weekStart,
    focusArea: focusArea,
  );
}

/// 全体戦略を決定
String _determineStrategy(
  ExamAnalysisResult analysis,
  List<WeakPointRecommendation> sortedWeakPoints,
) {
  if (analysis.overallAccuracy >= 0.8) {
    return '実力を維持しながら、弱点を重点的に克服することで、さらに上を目指しましょう。';
  } else if (analysis.overallAccuracy >= 0.6) {
    return '基礎を固めつつ、弱点分野への集中学習を進めます。段階的な実力向上を目指します。';
  } else {
    return '基礎から丁寧に学習し直すことが重要です。焦らず、確実な理解を心がけましょう。';
  }
}

/// JSONから学習計画をパース
LearningPlan _parseLearningPlan(Map<String, dynamic> data) {
  final prioritizedItems = (data['prioritizedItems'] as List?)?.map((item) {
    return LearningPlanItem(
      id: item['id'] ?? '',
      category: item['category'] ?? '',
      priority: item['priority'] ?? 3,
      recommendedDaysPerWeek: item['recommendedDaysPerWeek'] ?? 2,
      recommendedMinutesPerSession: item['recommendedMinutesPerSession'] ?? 20,
      description: item['description'] ?? '',
      createdAt: DateTime.parse(item['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }).toList() ?? [];

  final currentWeekData = data['currentWeekSchedule'] as Map<String, dynamic>?;
  final currentWeekSchedule = WeeklySchedule(
    schedule: prioritizedItems,
    totalMinutesPerWeek: currentWeekData?['totalMinutesPerWeek'] ?? 0,
    weekStartDate: DateTime.parse(
      currentWeekData?['weekStartDate'] ?? DateTime.now().toIso8601String(),
    ),
    focusArea: currentWeekData?['focusArea'] ?? '',
  );

  return LearningPlan(
    userId: data['userId'] ?? '',
    prioritizedItems: prioritizedItems,
    currentWeekSchedule: currentWeekSchedule,
    nextWeeksSchedules: [],
    generatedAt: DateTime.parse(
      data['generatedAt'] ?? DateTime.now().toIso8601String(),
    ),
    overallStrategy: data['overallStrategy'] ?? '',
  );
}

/// 学習計画をFirebaseに保存
Future<void> saveLearningPlan(LearningPlan plan) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('learningPlans')
        .add(plan.toJson());
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}
