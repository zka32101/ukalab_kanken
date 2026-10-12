import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/analytics.dart';
import 'package:kanken/models/learning_goal.dart';

void main() {
  group('LearningAnalytics Tests', () {
    test('LearningAnalytics can be created', () {
      final analytics = LearningAnalytics(
        userId: 'user1',
        totalStudyMinutes: 120,
        averageAccuracy: 0.85,
        totalQuestionsAttempted: 100,
        correctAnswers: 85,
        currentStreak: 7,
        longestStreak: 15,
        lastStudyDate: DateTime.now(),
        categoryStats: {'kanji': 50, 'reading': 50},
      );

      expect(analytics.userId, equals('user1'));
      expect(analytics.totalStudyMinutes, equals(120));
      expect(analytics.averageAccuracy, equals(0.85));
      expect(analytics.accuracyPercentage, equals(85.0));
    });

    test('JSON round-trip serialization', () {
      final original = LearningAnalytics(
        userId: 'user1',
        totalStudyMinutes: 120,
        averageAccuracy: 0.85,
        totalQuestionsAttempted: 100,
        correctAnswers: 85,
        currentStreak: 7,
        longestStreak: 15,
        lastStudyDate: DateTime(2026, 9, 13),
        categoryStats: {'kanji': 50, 'reading': 50},
      );

      final json = original.toJson();
      final fromJson = LearningAnalytics.fromJson(json);

      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.totalStudyMinutes, equals(original.totalStudyMinutes));
      expect(fromJson.averageAccuracy, equals(original.averageAccuracy));
      expect(fromJson.correctAnswers, equals(original.correctAnswers));
    });
  });

  group('GrowthData Tests', () {
    test('GrowthData can be created', () {
      final date = DateTime.now();
      final growth = GrowthData(
        date: date,
        accuracy: 0.82,
        correctCount: 41,
        totalCount: 50,
        studyMinutes: 30,
      );

      expect(growth.date, equals(date));
      expect(growth.accuracy, equals(0.82));
      expect(growth.correctCount, equals(41));
      expect(growth.totalCount, equals(50));
    });

    test('JSON round-trip serialization', () {
      final original = GrowthData(
        date: DateTime(2026, 9, 13),
        accuracy: 0.82,
        correctCount: 41,
        totalCount: 50,
        studyMinutes: 30,
      );

      final json = original.toJson();
      final fromJson = GrowthData.fromJson(json);

      expect(fromJson.accuracy, equals(original.accuracy));
      expect(fromJson.correctCount, equals(original.correctCount));
      expect(fromJson.studyMinutes, equals(original.studyMinutes));
    });
  });

  group('LearningTrend Tests', () {
    test('LearningTrend can be created', () {
      final trend = LearningTrend(
        category: '音読み',
        trendData: [0.7, 0.75, 0.8, 0.82, 0.85],
        averageTrend: 0.784,
        trend: 'up',
      );

      expect(trend.category, equals('音読み'));
      expect(trend.trendData.length, equals(5));
      expect(trend.trend, equals('up'));
    });

    test('JSON round-trip serialization', () {
      final original = LearningTrend(
        category: '音読み',
        trendData: [0.7, 0.75, 0.8, 0.82, 0.85],
        averageTrend: 0.784,
        trend: 'up',
      );

      final json = original.toJson();
      final fromJson = LearningTrend.fromJson(json);

      expect(fromJson.category, equals(original.category));
      expect(fromJson.averageTrend, equals(original.averageTrend));
      expect(fromJson.trend, equals(original.trend));
    });
  });

  group('LearningGoal Tests', () {
    LearningGoal make({
      String goalId = 'goal1',
      GoalType type = GoalType.accuracyRate,
      int targetValue = 100,
      int currentValue = 0,
      DateTime? deadline,
      DateTime? createdAt,
    }) =>
        LearningGoal(
          goalId: goalId,
          userId: 'user1',
          type: type,
          targetValue: targetValue,
          currentValue: currentValue,
          createdAt: createdAt ?? DateTime.now(),
          deadline: deadline,
        );

    test('LearningGoal can be created', () {
      final goal = make(
        targetValue: 80,
        deadline: DateTime.now().add(const Duration(days: 1)),
      );

      expect(goal.goalId, equals('goal1'));
      expect(goal.type, equals(GoalType.accuracyRate));
      expect(goal.isActive, isTrue);
      expect(goal.isAchieved, isFalse);
      expect(goal.isExpired, isFalse);
    });

    test('progressRate calculates correctly', () {
      final goal = make(targetValue: 100, currentValue: 50);

      expect(goal.progressRate, equals(0.5));
      expect(goal.progressPercentage, equals(50));
    });

    test('progressRate is clamped and safe for zero target', () {
      expect(make(targetValue: 100, currentValue: 150).progressRate, equals(1.0));
      expect(make(targetValue: 0, currentValue: 10).progressRate, equals(0.0));
    });

    test('isExpired reflects deadline', () {
      final past = make(deadline: DateTime.now().subtract(const Duration(days: 1)));
      expect(past.isExpired, isTrue);
      expect(make().isExpired, isFalse);
    });

    test('typeLabel and unit follow the goal type', () {
      final goal = make(type: GoalType.weeklyStudyMinutes);
      expect(goal.typeLabel, equals('週間学習時間'));
      expect(goal.unit, equals('分'));
    });

    test('JSON round-trip serialization', () {
      final original = make(
        goalId: 'goal1',
        type: GoalType.streakDays,
        targetValue: 80,
        currentValue: 40,
        deadline: DateTime(2026, 9, 14),
        createdAt: DateTime(2026, 9, 13),
      );

      final fromJson = LearningGoal.fromJson(original.toJson());

      expect(fromJson.goalId, equals(original.goalId));
      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.type, equals(original.type));
      expect(fromJson.targetValue, equals(original.targetValue));
      expect(fromJson.currentValue, equals(original.currentValue));
      expect(fromJson.deadline, equals(original.deadline));
    });
  });

  group('StudyEfficiency Tests', () {
    test('StudyEfficiency can be created', () {
      final efficiency = StudyEfficiency(
        userId: 'user1',
        minutesStudied: 60,
        questionsCompleted: 50,
        accuracyRate: 0.85,
        efficiencyScore: 71.25,
        calculatedAt: DateTime.now(),
      );

      expect(efficiency.userId, equals('user1'));
      expect(efficiency.minutesStudied, equals(60));
      expect(efficiency.questionsCompleted, equals(50));
      expect(efficiency.accuracyRate, equals(0.85));
    });

    test('questionsPerMinute calculates correctly', () {
      final efficiency = StudyEfficiency(
        userId: 'user1',
        minutesStudied: 60,
        questionsCompleted: 50,
        accuracyRate: 0.85,
        efficiencyScore: 71.25,
        calculatedAt: DateTime.now(),
      );

      expect(efficiency.questionsPerMinute, closeTo(0.833, 0.01));
    });

    test('questionsPerMinute handles zero minutes', () {
      final efficiency = StudyEfficiency(
        userId: 'user1',
        minutesStudied: 0,
        questionsCompleted: 50,
        accuracyRate: 0.85,
        efficiencyScore: 0,
        calculatedAt: DateTime.now(),
      );

      expect(efficiency.questionsPerMinute, equals(0));
    });

    test('JSON round-trip serialization', () {
      final original = StudyEfficiency(
        userId: 'user1',
        minutesStudied: 60,
        questionsCompleted: 50,
        accuracyRate: 0.85,
        efficiencyScore: 71.25,
        calculatedAt: DateTime(2026, 9, 13),
      );

      final json = original.toJson();
      final fromJson = StudyEfficiency.fromJson(json);

      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.minutesStudied, equals(original.minutesStudied));
      expect(fromJson.questionsCompleted, equals(original.questionsCompleted));
      expect(fromJson.accuracyRate, equals(original.accuracyRate));
    });
  });
}
