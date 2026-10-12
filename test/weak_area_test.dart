import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/weak_area.dart';

void main() {
  group('WeakLevel Tests', () {
    test('WeakLevel enum values exist', () {
      expect(WeakLevel.excellent, isNotNull);
      expect(WeakLevel.good, isNotNull);
      expect(WeakLevel.normal, isNotNull);
      expect(WeakLevel.weak, isNotNull);
      expect(WeakLevel.veryWeak, isNotNull);
    });
  });

  group('WeakArea Tests', () {
    test('WeakArea can be created with all fields', () {
      final weakArea = WeakArea(
        categoryId: 'cat1',
        categoryName: '音読み',
        totalAttempts: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        level: WeakLevel.good,
        recentStreakDays: 5,
        lastAttemptAt: DateTime(2026, 9, 13),
        problematicKanjiIds: ['kan1', 'kan2'],
      );

      expect(weakArea.categoryId, equals('cat1'));
      expect(weakArea.categoryName, equals('音読み'));
      expect(weakArea.totalAttempts, equals(100));
      expect(weakArea.correctAnswers, equals(75));
      expect(weakArea.level, equals(WeakLevel.good));
      expect(weakArea.recentStreakDays, equals(5));
      expect(weakArea.problematicKanjiIds.length, equals(2));
    });

    test('getAccuracyPercentage calculates correctly', () {
      final weakArea = WeakArea(
        categoryId: 'cat1',
        categoryName: 'テスト',
        totalAttempts: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        level: WeakLevel.good,
        recentStreakDays: 0,
        lastAttemptAt: DateTime.now(),
      );

      expect(weakArea.getAccuracyPercentage(), equals('75.0%'));
    });

    test('getAccuracyPercentage handles zero attempts', () {
      final weakArea = WeakArea(
        categoryId: 'cat1',
        categoryName: 'テスト',
        totalAttempts: 0,
        correctAnswers: 0,
        accuracyRate: 0.0,
        level: WeakLevel.excellent,
        recentStreakDays: 0,
        lastAttemptAt: DateTime.now(),
      );

      expect(weakArea.getAccuracyPercentage(), equals('0.0%'));
    });

    test('getLevelLabel returns Japanese labels', () {
      expect(
        WeakArea(
          categoryId: 'cat1',
          categoryName: 'テスト',
          totalAttempts: 100,
          correctAnswers: 95,
          accuracyRate: 0.95,
          level: WeakLevel.excellent,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ).getLevelLabel(),
        equals('優秀'),
      );

      expect(
        WeakArea(
          categoryId: 'cat1',
          categoryName: 'テスト',
          totalAttempts: 100,
          correctAnswers: 25,
          accuracyRate: 0.25,
          level: WeakLevel.veryWeak,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ).getLevelLabel(),
        equals('要改善'),
      );
    });

    test('getLevelEmoji returns correct emojis', () {
      expect(
        WeakArea(
          categoryId: 'cat1',
          categoryName: 'テスト',
          totalAttempts: 100,
          correctAnswers: 95,
          accuracyRate: 0.95,
          level: WeakLevel.excellent,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ).getLevelEmoji(),
        equals('⭐⭐⭐'),
      );

      expect(
        WeakArea(
          categoryId: 'cat1',
          categoryName: 'テスト',
          totalAttempts: 100,
          correctAnswers: 25,
          accuracyRate: 0.25,
          level: WeakLevel.veryWeak,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ).getLevelEmoji(),
        equals('🔴'),
      );
    });

    test('needsImprovement returns correct boolean', () {
      final goodArea = WeakArea(
        categoryId: 'cat1',
        categoryName: 'テスト',
        totalAttempts: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        level: WeakLevel.good,
        recentStreakDays: 0,
        lastAttemptAt: DateTime.now(),
      );

      final weakArea = WeakArea(
        categoryId: 'cat1',
        categoryName: 'テスト',
        totalAttempts: 100,
        correctAnswers: 25,
        accuracyRate: 0.25,
        level: WeakLevel.weak,
        recentStreakDays: 0,
        lastAttemptAt: DateTime.now(),
      );

      expect(goodArea.needsImprovement, isFalse);
      expect(weakArea.needsImprovement, isTrue);
    });

    test('getRecommendedFrequency returns correct number of days', () {
      expect(
        WeakArea(
          categoryId: 'cat1',
          categoryName: 'テスト',
          totalAttempts: 100,
          correctAnswers: 25,
          accuracyRate: 0.25,
          level: WeakLevel.veryWeak,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ).getRecommendedFrequency(),
        equals(1),
      );

      expect(
        WeakArea(
          categoryId: 'cat1',
          categoryName: 'テスト',
          totalAttempts: 100,
          correctAnswers: 75,
          accuracyRate: 0.75,
          level: WeakLevel.good,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ).getRecommendedFrequency(),
        equals(14),
      );
    });

    test('getRecommendedQuestionCount returns correct range', () {
      expect(
        WeakArea(
          categoryId: 'cat1',
          categoryName: 'テスト',
          totalAttempts: 100,
          correctAnswers: 25,
          accuracyRate: 0.25,
          level: WeakLevel.veryWeak,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ).getRecommendedQuestionCount(),
        equals(25),
      );

      expect(
        WeakArea(
          categoryId: 'cat1',
          categoryName: 'テスト',
          totalAttempts: 100,
          correctAnswers: 75,
          accuracyRate: 0.75,
          level: WeakLevel.good,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ).getRecommendedQuestionCount(),
        equals(5),
      );
    });

    test('JSON round-trip serialization', () {
      final original = WeakArea(
        categoryId: 'cat1',
        categoryName: '音読み',
        totalAttempts: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        level: WeakLevel.good,
        recentStreakDays: 5,
        lastAttemptAt: DateTime(2026, 9, 13),
        problematicKanjiIds: ['kan1', 'kan2'],
      );

      final json = original.toJson();
      final fromJson = WeakArea.fromJson(json);

      expect(fromJson.categoryId, equals(original.categoryId));
      expect(fromJson.categoryName, equals(original.categoryName));
      expect(fromJson.totalAttempts, equals(original.totalAttempts));
      expect(fromJson.correctAnswers, equals(original.correctAnswers));
      expect(fromJson.level, equals(original.level));
      expect(fromJson.recentStreakDays, equals(original.recentStreakDays));
      expect(fromJson.problematicKanjiIds, equals(original.problematicKanjiIds));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = {
        'categoryId': 'cat1',
        'categoryName': '音読み',
      };

      final weakArea = WeakArea.fromJson(json);
      expect(weakArea.categoryId, equals('cat1'));
      expect(weakArea.totalAttempts, equals(0));
      expect(weakArea.correctAnswers, equals(0));
      expect(weakArea.level, equals(WeakLevel.excellent));
    });

    test('toString returns readable format', () {
      final weakArea = WeakArea(
        categoryId: 'cat1',
        categoryName: '音読み',
        totalAttempts: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        level: WeakLevel.good,
        recentStreakDays: 5,
        lastAttemptAt: DateTime(2026, 9, 13),
      );

      expect(weakArea.toString(), contains('WeakArea'));
      expect(weakArea.toString(), contains('音読み'));
    });
  });

  group('WeakAreaAnalysis Tests', () {
    test('WeakAreaAnalysis calculates overall accuracy', () {
      final areas = [
        WeakArea(
          categoryId: 'cat1',
          categoryName: '音読み',
          totalAttempts: 100,
          correctAnswers: 90,
          accuracyRate: 0.9,
          level: WeakLevel.good,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ),
        WeakArea(
          categoryId: 'cat2',
          categoryName: '訓読み',
          totalAttempts: 100,
          correctAnswers: 70,
          accuracyRate: 0.7,
          level: WeakLevel.normal,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ),
      ];

      final analysis = WeakAreaAnalysis(
        allAreas: areas,
        overallAccuracy: 0.8,
        analyzedAt: DateTime.now(),
      );
      expect(analysis.overallAccuracy, closeTo(0.8, 0.01));
    });

    test('WeakAreaAnalysis filters weak areas', () {
      final areas = [
        WeakArea(
          categoryId: 'cat1',
          categoryName: '音読み',
          totalAttempts: 100,
          correctAnswers: 90,
          accuracyRate: 0.9,
          level: WeakLevel.good,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ),
        WeakArea(
          categoryId: 'cat2',
          categoryName: '訓読み',
          totalAttempts: 100,
          correctAnswers: 25,
          accuracyRate: 0.25,
          level: WeakLevel.weak,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ),
      ];

      final analysis = WeakAreaAnalysis(
        allAreas: areas,
        overallAccuracy: 0.575,
        analyzedAt: DateTime.now(),
      );
      final weakAreas = analysis.weakAreas;
      expect(weakAreas.length, equals(1));
      expect(weakAreas[0].categoryName, equals('訓読み'));
    });

    test('getWorstArea returns area with lowest accuracy', () {
      final areas = [
        WeakArea(
          categoryId: 'cat1',
          categoryName: '音読み',
          totalAttempts: 100,
          correctAnswers: 90,
          accuracyRate: 0.9,
          level: WeakLevel.good,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ),
        WeakArea(
          categoryId: 'cat2',
          categoryName: '訓読み',
          totalAttempts: 100,
          correctAnswers: 25,
          accuracyRate: 0.25,
          level: WeakLevel.weak,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ),
      ];

      final analysis = WeakAreaAnalysis(
        allAreas: areas,
        overallAccuracy: 0.575,
        analyzedAt: DateTime.now(),
      );
      final worst = analysis.getWorstArea();
      expect(worst?.categoryName, equals('訓読み'));
    });

    test('weakPercentage calculates correctly', () {
      final areas = [
        WeakArea(
          categoryId: 'cat1',
          categoryName: '音読み',
          totalAttempts: 100,
          correctAnswers: 90,
          accuracyRate: 0.9,
          level: WeakLevel.good,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ),
        WeakArea(
          categoryId: 'cat2',
          categoryName: '訓読み',
          totalAttempts: 100,
          correctAnswers: 25,
          accuracyRate: 0.25,
          level: WeakLevel.weak,
          recentStreakDays: 0,
          lastAttemptAt: DateTime.now(),
        ),
      ];

      final analysis = WeakAreaAnalysis(
        allAreas: areas,
        overallAccuracy: 0.575,
        analyzedAt: DateTime.now(),
      );
      expect(analysis.weakPercentage, closeTo(0.5, 0.01));
    });
  });
}
