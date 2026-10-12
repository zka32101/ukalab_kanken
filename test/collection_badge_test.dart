import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/collection_badge.dart';

void main() {
  group('BadgeRarity Tests', () {
    test('BadgeRarity enum values exist', () {
      expect(BadgeRarity.common, isNotNull);
      expect(BadgeRarity.uncommon, isNotNull);
      expect(BadgeRarity.rare, isNotNull);
      expect(BadgeRarity.epic, isNotNull);
      expect(BadgeRarity.legendary, isNotNull);
    });
  });

  group('BadgeCategory Tests', () {
    test('BadgeCategory enum values exist', () {
      expect(BadgeCategory.achievement, isNotNull);
      expect(BadgeCategory.streak, isNotNull);
      expect(BadgeCategory.challenge, isNotNull);
      expect(BadgeCategory.event, isNotNull);
      expect(BadgeCategory.special, isNotNull);
    });
  });

  group('CollectionBadge Tests', () {
    test('CollectionBadge can be created with all fields', () {
      final badge = CollectionBadge(
        badgeId: 'badge1',
        name: 'はじまり',
        description: '最初のバッジ',
        rarity: BadgeRarity.common,
        category: BadgeCategory.achievement,
        iconEmoji: '🎖️',
        requiredCount: 10,
        conditionText: '10問正解',
        isHidden: false,
        rewardCoins: 50,
        createdAt: DateTime(2026, 9, 13),
      );

      expect(badge.badgeId, equals('badge1'));
      expect(badge.name, equals('はじまり'));
      expect(badge.rarity, equals(BadgeRarity.common));
      expect(badge.category, equals(BadgeCategory.achievement));
      expect(badge.requiredCount, equals(10));
      expect(badge.rewardCoins, equals(50));
    });

    test('getRarityLabel returns Japanese labels', () {
      expect(
        CollectionBadge(
          badgeId: 'badge1',
          name: 'テスト',
          description: 'テスト',
          rarity: BadgeRarity.common,
          category: BadgeCategory.achievement,
          iconEmoji: '🎖️',
          requiredCount: 10,
          conditionText: 'テスト',
          createdAt: DateTime.now(),
        ).getRarityLabel(),
        equals('一般'),
      );

      expect(
        CollectionBadge(
          badgeId: 'badge1',
          name: 'テスト',
          description: 'テスト',
          rarity: BadgeRarity.legendary,
          category: BadgeCategory.achievement,
          iconEmoji: '🎖️',
          requiredCount: 10,
          conditionText: 'テスト',
          createdAt: DateTime.now(),
        ).getRarityLabel(),
        equals('伝説'),
      );
    });

    test('getRarityColor returns correct colors', () {
      expect(
        CollectionBadge(
          badgeId: 'badge1',
          name: 'テスト',
          description: 'テスト',
          rarity: BadgeRarity.common,
          category: BadgeCategory.achievement,
          iconEmoji: '🎖️',
          requiredCount: 10,
          conditionText: 'テスト',
          createdAt: DateTime.now(),
        ).getRarityColor(),
        equals(0xFF9E9E9E),
      );

      expect(
        CollectionBadge(
          badgeId: 'badge1',
          name: 'テスト',
          description: 'テスト',
          rarity: BadgeRarity.legendary,
          category: BadgeCategory.achievement,
          iconEmoji: '🎖️',
          requiredCount: 10,
          conditionText: 'テスト',
          createdAt: DateTime.now(),
        ).getRarityColor(),
        equals(0xFFFFD700),
      );
    });

    test('getCategoryLabel returns Japanese labels', () {
      expect(
        CollectionBadge(
          badgeId: 'badge1',
          name: 'テスト',
          description: 'テスト',
          rarity: BadgeRarity.common,
          category: BadgeCategory.achievement,
          iconEmoji: '🎖️',
          requiredCount: 10,
          conditionText: 'テスト',
          createdAt: DateTime.now(),
        ).getCategoryLabel(),
        equals('達成'),
      );

      expect(
        CollectionBadge(
          badgeId: 'badge1',
          name: 'テスト',
          description: 'テスト',
          rarity: BadgeRarity.common,
          category: BadgeCategory.special,
          iconEmoji: '🎖️',
          requiredCount: 10,
          conditionText: 'テスト',
          createdAt: DateTime.now(),
        ).getCategoryLabel(),
        equals('スペシャル'),
      );
    });

    test('JSON round-trip serialization', () {
      final createdAt = DateTime(2026, 9, 13);
      final original = CollectionBadge(
        badgeId: 'badge1',
        name: 'はじまり',
        description: '最初のバッジ',
        rarity: BadgeRarity.uncommon,
        category: BadgeCategory.achievement,
        iconEmoji: '🎖️',
        requiredCount: 10,
        conditionText: '10問正解',
        isHidden: false,
        rewardCoins: 50,
        createdAt: createdAt,
      );

      final json = original.toJson();
      final fromJson = CollectionBadge.fromJson(json);

      expect(fromJson.badgeId, equals(original.badgeId));
      expect(fromJson.name, equals(original.name));
      expect(fromJson.description, equals(original.description));
      expect(fromJson.rarity, equals(original.rarity));
      expect(fromJson.category, equals(original.category));
      expect(fromJson.iconEmoji, equals(original.iconEmoji));
      expect(fromJson.requiredCount, equals(original.requiredCount));
      expect(fromJson.isHidden, equals(original.isHidden));
      expect(fromJson.rewardCoins, equals(original.rewardCoins));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = {
        'badgeId': 'badge1',
        'name': 'テスト',
      };

      final badge = CollectionBadge.fromJson(json);
      expect(badge.badgeId, equals('badge1'));
      expect(badge.name, equals('テスト'));
      expect(badge.description, equals(''));
      expect(badge.rarity, equals(BadgeRarity.common));
      expect(badge.category, equals(BadgeCategory.achievement));
      expect(badge.isHidden, isFalse);
      expect(badge.rewardCoins, equals(0));
    });
  });

  group('UserBadgeProgress Tests', () {
    test('UserBadgeProgress can be created', () {
      final progress = UserBadgeProgress(
        progressId: 'prog1',
        userId: 'user1',
        badgeId: 'badge1',
        currentCount: 7,
        isAcquired: false,
        lastUpdatedAt: DateTime.now(),
      );

      expect(progress.progressId, equals('prog1'));
      expect(progress.userId, equals('user1'));
      expect(progress.badgeId, equals('badge1'));
      expect(progress.currentCount, equals(7));
      expect(progress.isAcquired, isFalse);
    });

    test('getProgress calculates correctly', () {
      final progress = UserBadgeProgress(
        progressId: 'prog1',
        userId: 'user1',
        badgeId: 'badge1',
        currentCount: 5,
        isAcquired: false,
        lastUpdatedAt: DateTime.now(),
      );

      expect(progress.getProgress(10), equals(0.5));
      expect(progress.getProgress(5), equals(1.0));
      expect(progress.getProgress(20), equals(0.25));
    });

    test('getProgressPercentage returns correct percentage', () {
      final progress = UserBadgeProgress(
        progressId: 'prog1',
        userId: 'user1',
        badgeId: 'badge1',
        currentCount: 75,
        isAcquired: false,
        lastUpdatedAt: DateTime.now(),
      );

      expect(progress.getProgressPercentage(100), equals('75%'));
    });

    test('canAcquire returns correct boolean', () {
      final notReady = UserBadgeProgress(
        progressId: 'prog1',
        userId: 'user1',
        badgeId: 'badge1',
        currentCount: 5,
        isAcquired: false,
        lastUpdatedAt: DateTime.now(),
      );

      final ready = UserBadgeProgress(
        progressId: 'prog2',
        userId: 'user1',
        badgeId: 'badge2',
        currentCount: 10,
        isAcquired: false,
        lastUpdatedAt: DateTime.now(),
      );

      final acquired = UserBadgeProgress(
        progressId: 'prog3',
        userId: 'user1',
        badgeId: 'badge3',
        currentCount: 10,
        isAcquired: true,
        lastUpdatedAt: DateTime.now(),
      );

      expect(notReady.canAcquire(10), isFalse);
      expect(ready.canAcquire(10), isTrue);
      expect(acquired.canAcquire(10), isFalse);
    });

    test('JSON round-trip serialization', () {
      final acquiredAt = DateTime(2026, 9, 13);
      final original = UserBadgeProgress(
        progressId: 'prog1',
        userId: 'user1',
        badgeId: 'badge1',
        currentCount: 10,
        isAcquired: true,
        acquiredAt: acquiredAt,
        lastUpdatedAt: DateTime(2026, 9, 14),
      );

      final json = original.toJson();
      final fromJson = UserBadgeProgress.fromJson(json);

      expect(fromJson.progressId, equals(original.progressId));
      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.badgeId, equals(original.badgeId));
      expect(fromJson.currentCount, equals(original.currentCount));
      expect(fromJson.isAcquired, equals(original.isAcquired));
    });
  });

  group('BadgeCollectionStats Tests', () {
    test('BadgeCollectionStats calculates completion percentage', () {
      final stats = BadgeCollectionStats(
        totalBadges: 20,
        acquiredCount: 10,
        hiddenBadges: 2,
        acquiredHiddenCount: 1,
        allProgress: [],
      );

      expect(stats.getCompletionPercentage(), equals(0.5));
    });

    test('getVisibleCompletionPercentage excludes hidden badges', () {
      final stats = BadgeCollectionStats(
        totalBadges: 20,
        acquiredCount: 10,
        hiddenBadges: 2,
        acquiredHiddenCount: 1,
        allProgress: [],
      );

      expect(stats.getVisibleCompletionPercentage(),
          closeTo(10 / 18, 0.01));
    });

    test('getHiddenDiscoveryPercentage calculates correctly', () {
      final stats = BadgeCollectionStats(
        totalBadges: 20,
        acquiredCount: 10,
        hiddenBadges: 4,
        acquiredHiddenCount: 2,
        allProgress: [],
      );

      expect(stats.getHiddenDiscoveryPercentage(), equals(0.5));
    });

    test('getStatusText returns readable format', () {
      final stats = BadgeCollectionStats(
        totalBadges: 20,
        acquiredCount: 10,
        hiddenBadges: 2,
        acquiredHiddenCount: 1,
        allProgress: [],
      );

      expect(stats.getStatusText(), equals('10 / 20 バッジ取得済み'));
    });
  });
}
