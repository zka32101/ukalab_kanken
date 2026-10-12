import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/global_event.dart';

void main() {
  group('EventType Tests', () {
    test('EventType enum values exist', () {
      expect(EventType.daily, isNotNull);
      expect(EventType.weekly, isNotNull);
      expect(EventType.monthly, isNotNull);
      expect(EventType.special, isNotNull);
    });
  });

  group('EventStatus Tests', () {
    test('EventStatus enum values exist', () {
      expect(EventStatus.upcoming, isNotNull);
      expect(EventStatus.active, isNotNull);
      expect(EventStatus.ended, isNotNull);
    });
  });

  group('GlobalEvent Tests', () {
    test('GlobalEvent can be created with all fields', () {
      final startAt = DateTime(2026, 9, 1);
      final endAt = DateTime(2026, 9, 8);

      final event = GlobalEvent(
        eventId: 'event1',
        eventName: 'チャレンジイベント',
        description: 'テストイベント',
        type: EventType.weekly,
        status: EventStatus.active,
        startAt: startAt,
        endAt: endAt,
        targetCategory: '音読み',
        targetScore: 100,
        participantCount: 50,
        rewards: {'rank_1': 500, 'rank_2': 300},
        bannerImageUrl: 'https://example.com/banner.jpg',
      );

      expect(event.eventId, equals('event1'));
      expect(event.eventName, equals('チャレンジイベント'));
      expect(event.description, equals('テストイベント'));
      expect(event.type, equals(EventType.weekly));
      expect(event.status, equals(EventStatus.active));
      expect(event.targetScore, equals(100));
      expect(event.participantCount, equals(50));
    });

    test('getProgressPercentage calculates correctly', () {
      final startAt = DateTime(2026, 9, 1);
      final endAt = DateTime(2026, 9, 8);

      final event = GlobalEvent(
        eventId: 'event1',
        eventName: 'テストイベント',
        description: 'テスト',
        type: EventType.weekly,
        status: EventStatus.active,
        startAt: startAt,
        endAt: endAt,
        targetCategory: '音読み',
        targetScore: 100,
      );

      // 進捗率は起動時の時刻に依存するため、範囲チェック
      final progress = event.getProgressPercentage();
      expect(progress, greaterThanOrEqualTo(0));
      expect(progress, lessThanOrEqualTo(100));
    });

    test('getPeriodLabel returns Japanese labels', () {
      final now = DateTime.now();

      expect(
        GlobalEvent(
          eventId: 'event1',
          eventName: 'テスト',
          description: 'テスト',
          type: EventType.daily,
          status: EventStatus.active,
          startAt: now,
          endAt: now.add(const Duration(hours: 1)),
          targetCategory: 'テスト',
          targetScore: 100,
        ).getPeriodLabel(),
        equals('日替わり'),
      );

      expect(
        GlobalEvent(
          eventId: 'event1',
          eventName: 'テスト',
          description: 'テスト',
          type: EventType.weekly,
          status: EventStatus.active,
          startAt: now,
          endAt: now.add(const Duration(days: 7)),
          targetCategory: 'テスト',
          targetScore: 100,
        ).getPeriodLabel(),
        equals('週間'),
      );

      expect(
        GlobalEvent(
          eventId: 'event1',
          eventName: 'テスト',
          description: 'テスト',
          type: EventType.monthly,
          status: EventStatus.active,
          startAt: now,
          endAt: now.add(const Duration(days: 30)),
          targetCategory: 'テスト',
          targetScore: 100,
        ).getPeriodLabel(),
        equals('月間'),
      );

      expect(
        GlobalEvent(
          eventId: 'event1',
          eventName: 'テスト',
          description: 'テスト',
          type: EventType.special,
          status: EventStatus.active,
          startAt: now,
          endAt: now.add(const Duration(days: 14)),
          targetCategory: 'テスト',
          targetScore: 100,
        ).getPeriodLabel(),
        equals('特別'),
      );
    });

    test('getStatusLabel returns Japanese labels', () {
      final now = DateTime.now();

      expect(
        GlobalEvent(
          eventId: 'event1',
          eventName: 'テスト',
          description: 'テスト',
          type: EventType.weekly,
          status: EventStatus.upcoming,
          startAt: now.add(const Duration(days: 1)),
          endAt: now.add(const Duration(days: 8)),
          targetCategory: 'テスト',
          targetScore: 100,
        ).getStatusLabel(),
        equals('開始前'),
      );

      expect(
        GlobalEvent(
          eventId: 'event1',
          eventName: 'テスト',
          description: 'テスト',
          type: EventType.weekly,
          status: EventStatus.active,
          startAt: now,
          endAt: now.add(const Duration(days: 7)),
          targetCategory: 'テスト',
          targetScore: 100,
        ).getStatusLabel(),
        equals('実行中'),
      );

      expect(
        GlobalEvent(
          eventId: 'event1',
          eventName: 'テスト',
          description: 'テスト',
          type: EventType.weekly,
          status: EventStatus.ended,
          startAt: now.subtract(const Duration(days: 7)),
          endAt: now,
          targetCategory: 'テスト',
          targetScore: 100,
        ).getStatusLabel(),
        equals('終了'),
      );
    });

    test('getStatusEmoji returns correct emojis', () {
      final now = DateTime.now();

      expect(
        GlobalEvent(
          eventId: 'event1',
          eventName: 'テスト',
          description: 'テスト',
          type: EventType.weekly,
          status: EventStatus.upcoming,
          startAt: now.add(const Duration(days: 1)),
          endAt: now.add(const Duration(days: 8)),
          targetCategory: 'テスト',
          targetScore: 100,
        ).getStatusEmoji(),
        equals('⏳'),
      );

      expect(
        GlobalEvent(
          eventId: 'event1',
          eventName: 'テスト',
          description: 'テスト',
          type: EventType.weekly,
          status: EventStatus.active,
          startAt: now,
          endAt: now.add(const Duration(days: 7)),
          targetCategory: 'テスト',
          targetScore: 100,
        ).getStatusEmoji(),
        equals('🔥'),
      );

      expect(
        GlobalEvent(
          eventId: 'event1',
          eventName: 'テスト',
          description: 'テスト',
          type: EventType.weekly,
          status: EventStatus.ended,
          startAt: now.subtract(const Duration(days: 7)),
          endAt: now,
          targetCategory: 'テスト',
          targetScore: 100,
        ).getStatusEmoji(),
        equals('✅'),
      );
    });

    test('canParticipate returns true only for active events', () {
      final now = DateTime.now();

      final activeEvent = GlobalEvent(
        eventId: 'event1',
        eventName: 'テスト',
        description: 'テスト',
        type: EventType.weekly,
        status: EventStatus.active,
        startAt: now,
        endAt: now.add(const Duration(days: 7)),
        targetCategory: 'テスト',
        targetScore: 100,
      );

      final upcomingEvent = GlobalEvent(
        eventId: 'event1',
        eventName: 'テスト',
        description: 'テスト',
        type: EventType.weekly,
        status: EventStatus.upcoming,
        startAt: now.add(const Duration(days: 1)),
        endAt: now.add(const Duration(days: 8)),
        targetCategory: 'テスト',
        targetScore: 100,
      );

      expect(activeEvent.canParticipate, isTrue);
      expect(upcomingEvent.canParticipate, isFalse);
    });

    test('getRewardForRank returns correct coins', () {
      final event = GlobalEvent(
        eventId: 'event1',
        eventName: 'テスト',
        description: 'テスト',
        type: EventType.weekly,
        status: EventStatus.active,
        startAt: DateTime.now(),
        endAt: DateTime.now().add(const Duration(days: 7)),
        targetCategory: 'テスト',
        targetScore: 100,
        rewards: {
          'rank_1': 500,
          'rank_2': 300,
          'rank_3': 100,
        },
      );

      expect(event.getRewardForRank(1), equals(500));
      expect(event.getRewardForRank(2), equals(300));
      expect(event.getRewardForRank(3), equals(100));
      expect(event.getRewardForRank(4), equals(0));
    });

    test('JSON round-trip serialization', () {
      final startAt = DateTime(2026, 9, 1);
      final endAt = DateTime(2026, 9, 8);

      final original = GlobalEvent(
        eventId: 'event1',
        eventName: 'チャレンジイベント',
        description: 'テストイベント',
        type: EventType.weekly,
        status: EventStatus.active,
        startAt: startAt,
        endAt: endAt,
        targetCategory: '音読み',
        targetScore: 100,
        participantCount: 50,
        rewards: {'rank_1': 500},
        bannerImageUrl: 'https://example.com/banner.jpg',
      );

      final json = original.toJson();
      final fromJson = GlobalEvent.fromJson(json);

      expect(fromJson.eventId, equals(original.eventId));
      expect(fromJson.eventName, equals(original.eventName));
      expect(fromJson.description, equals(original.description));
      expect(fromJson.type, equals(original.type));
      expect(fromJson.status, equals(original.status));
      expect(fromJson.targetScore, equals(original.targetScore));
      expect(fromJson.participantCount, equals(original.participantCount));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = {
        'eventId': 'event1',
        'eventName': 'テスト',
      };

      final event = GlobalEvent.fromJson(json);
      expect(event.eventId, equals('event1'));
      expect(event.eventName, equals('テスト'));
      expect(event.description, equals(''));
      expect(event.type, equals(EventType.special));
      expect(event.status, equals(EventStatus.upcoming));
    });
  });

  group('EventParticipation Tests', () {
    test('EventParticipation can be created', () {
      final participation = EventParticipation(
        participationId: 'part1',
        eventId: 'event1',
        userId: 'user1',
        userName: 'テストユーザー',
        currentScore: 150,
        isCompleted: false,
        rank: 5,
        rewardCoins: 0,
        joinedAt: DateTime(2026, 9, 13),
      );

      expect(participation.participationId, equals('part1'));
      expect(participation.eventId, equals('event1'));
      expect(participation.userId, equals('user1'));
      expect(participation.userName, equals('テストユーザー'));
      expect(participation.currentScore, equals(150));
      expect(participation.isCompleted, isFalse);
      expect(participation.rank, equals(5));
    });

    test('isGoalAchieved returns correct boolean', () {
      final participation1 = EventParticipation(
        participationId: 'part1',
        eventId: 'event1',
        userId: 'user1',
        userName: 'テストユーザー',
        currentScore: 150,
        isCompleted: false,
        rank: 5,
        rewardCoins: 0,
        joinedAt: DateTime.now(),
      );

      final participation2 = EventParticipation(
        participationId: 'part2',
        eventId: 'event1',
        userId: 'user2',
        userName: 'テストユーザー2',
        currentScore: 50,
        isCompleted: false,
        rank: 10,
        rewardCoins: 0,
        joinedAt: DateTime.now(),
      );

      expect(participation1.isGoalAchieved(100), isTrue);
      expect(participation2.isGoalAchieved(100), isFalse);
    });

    test('getRankBadge returns correct emojis', () {
      final rank1 = EventParticipation(
        participationId: 'part1',
        eventId: 'event1',
        userId: 'user1',
        userName: 'テスト',
        currentScore: 150,
        isCompleted: false,
        rank: 1,
        rewardCoins: 500,
        joinedAt: DateTime.now(),
      );

      final rank2 = EventParticipation(
        participationId: 'part2',
        eventId: 'event1',
        userId: 'user2',
        userName: 'テスト',
        currentScore: 140,
        isCompleted: false,
        rank: 2,
        rewardCoins: 300,
        joinedAt: DateTime.now(),
      );

      final rank3 = EventParticipation(
        participationId: 'part3',
        eventId: 'event1',
        userId: 'user3',
        userName: 'テスト',
        currentScore: 130,
        isCompleted: false,
        rank: 3,
        rewardCoins: 100,
        joinedAt: DateTime.now(),
      );

      final rank5 = EventParticipation(
        participationId: 'part4',
        eventId: 'event1',
        userId: 'user4',
        userName: 'テスト',
        currentScore: 110,
        isCompleted: false,
        rank: 5,
        rewardCoins: 0,
        joinedAt: DateTime.now(),
      );

      expect(rank1.getRankBadge(), equals('🥇'));
      expect(rank2.getRankBadge(), equals('🥈'));
      expect(rank3.getRankBadge(), equals('🥉'));
      expect(rank5.getRankBadge(), equals('5位'));
    });

    test('JSON round-trip serialization', () {
      final joinedAt = DateTime(2026, 9, 13);
      final completedAt = DateTime(2026, 9, 14);

      final original = EventParticipation(
        participationId: 'part1',
        eventId: 'event1',
        userId: 'user1',
        userName: 'テストユーザー',
        currentScore: 200,
        isCompleted: true,
        rank: 1,
        rewardCoins: 500,
        joinedAt: joinedAt,
        completedAt: completedAt,
      );

      final json = original.toJson();
      final fromJson = EventParticipation.fromJson(json);

      expect(fromJson.participationId, equals(original.participationId));
      expect(fromJson.eventId, equals(original.eventId));
      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.userName, equals(original.userName));
      expect(fromJson.currentScore, equals(original.currentScore));
      expect(fromJson.isCompleted, equals(original.isCompleted));
      expect(fromJson.rank, equals(original.rank));
      expect(fromJson.rewardCoins, equals(original.rewardCoins));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = {
        'participationId': 'part1',
        'eventId': 'event1',
        'userId': 'user1',
      };

      final participation = EventParticipation.fromJson(json);
      expect(participation.participationId, equals('part1'));
      expect(participation.eventId, equals('event1'));
      expect(participation.userId, equals('user1'));
      expect(participation.userName, equals('Unknown'));
      expect(participation.currentScore, equals(0));
      expect(participation.isCompleted, isFalse);
    });
  });
}
