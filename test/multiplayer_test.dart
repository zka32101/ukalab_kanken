import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/multiplayer.dart';

void main() {
  group('BattleParticipant Tests', () {
    test('BattleParticipant can be created', () {
      final participant = BattleParticipant(
        userId: 'user1',
        displayName: '太郎',
        avatarUrl: null,
        currentScore: 100,
        correctAnswers: 5,
        level: 10,
        joinedAt: DateTime.now(),
        isReady: true,
        isFinished: false,
      );

      expect(participant.userId, equals('user1'));
      expect(participant.displayName, equals('太郎'));
      expect(participant.currentScore, equals(100));
      expect(participant.isReady, isTrue);
    });

    test('JSON round-trip serialization', () {
      final original = BattleParticipant(
        userId: 'user1',
        displayName: '太郎',
        avatarUrl: null,
        currentScore: 100,
        correctAnswers: 5,
        level: 10,
        joinedAt: DateTime(2026, 9, 13),
        isReady: true,
        isFinished: false,
      );

      final json = original.toJson();
      final fromJson = BattleParticipant.fromJson(json);

      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.displayName, equals(original.displayName));
      expect(fromJson.currentScore, equals(original.currentScore));
      expect(fromJson.isReady, equals(original.isReady));
    });
  });

  group('BattleRoom Tests', () {
    test('BattleRoom can be created', () {
      final participant = BattleParticipant(
        userId: 'user1',
        displayName: '太郎',
        avatarUrl: null,
        currentScore: 0,
        correctAnswers: 0,
        level: 10,
        joinedAt: DateTime.now(),
        isReady: true,
        isFinished: false,
      );

      final room = BattleRoom(
        roomId: 'room1',
        creatorId: 'user1',
        roomName: 'テストルーム',
        examLevel: 10,
        maxParticipants: 2,
        participants: [participant],
        status: 'waiting',
        totalQuestions: 10,
        timePerQuestionSeconds: 60,
        createdAt: DateTime.now(),
      );

      expect(room.roomId, equals('room1'));
      expect(room.roomName, equals('テストルーム'));
      expect(room.participants.length, equals(1));
      expect(room.status, equals('waiting'));
    });

    test('canStart returns correct status', () {
      final participant1 = BattleParticipant(
        userId: 'user1',
        displayName: '太郎',
        avatarUrl: null,
        currentScore: 0,
        correctAnswers: 0,
        level: 10,
        joinedAt: DateTime.now(),
        isReady: true,
        isFinished: false,
      );

      final participant2 = BattleParticipant(
        userId: 'user2',
        displayName: '花子',
        avatarUrl: null,
        currentScore: 0,
        correctAnswers: 0,
        level: 10,
        joinedAt: DateTime.now(),
        isReady: true,
        isFinished: false,
      );

      final roomWithOneParticipant = BattleRoom(
        roomId: 'room1',
        creatorId: 'user1',
        roomName: 'テストルーム',
        examLevel: 10,
        maxParticipants: 2,
        participants: [participant1],
        status: 'waiting',
        totalQuestions: 10,
        timePerQuestionSeconds: 60,
        createdAt: DateTime.now(),
      );

      final roomWithTwoParticipants = BattleRoom(
        roomId: 'room2',
        creatorId: 'user1',
        roomName: 'テストルーム',
        examLevel: 10,
        maxParticipants: 2,
        participants: [participant1, participant2],
        status: 'waiting',
        totalQuestions: 10,
        timePerQuestionSeconds: 60,
        createdAt: DateTime.now(),
      );

      expect(roomWithOneParticipant.canStart(), isFalse);
      expect(roomWithTwoParticipants.canStart(), isTrue);
    });

    test('isFull returns correct status', () {
      final participant1 = BattleParticipant(
        userId: 'user1',
        displayName: '太郎',
        avatarUrl: null,
        currentScore: 0,
        correctAnswers: 0,
        level: 10,
        joinedAt: DateTime.now(),
        isReady: true,
        isFinished: false,
      );

      final participant2 = BattleParticipant(
        userId: 'user2',
        displayName: '花子',
        avatarUrl: null,
        currentScore: 0,
        correctAnswers: 0,
        level: 10,
        joinedAt: DateTime.now(),
        isReady: true,
        isFinished: false,
      );

      final notFullRoom = BattleRoom(
        roomId: 'room1',
        creatorId: 'user1',
        roomName: 'テストルーム',
        examLevel: 10,
        maxParticipants: 4,
        participants: [participant1],
        status: 'waiting',
        totalQuestions: 10,
        timePerQuestionSeconds: 60,
        createdAt: DateTime.now(),
      );

      final fullRoom = BattleRoom(
        roomId: 'room2',
        creatorId: 'user1',
        roomName: 'テストルーム',
        examLevel: 10,
        maxParticipants: 2,
        participants: [participant1, participant2],
        status: 'waiting',
        totalQuestions: 10,
        timePerQuestionSeconds: 60,
        createdAt: DateTime.now(),
      );

      expect(notFullRoom.isFull(), isFalse);
      expect(fullRoom.isFull(), isTrue);
    });
  });

  group('BattleResult Tests', () {
    test('BattleResult can be created', () {
      final participants = [
        BattleParticipant(
          userId: 'user1',
          displayName: '太郎',
          avatarUrl: null,
          currentScore: 100,
          correctAnswers: 5,
          level: 10,
          joinedAt: DateTime.now(),
          isReady: true,
          isFinished: true,
        ),
        BattleParticipant(
          userId: 'user2',
          displayName: '花子',
          avatarUrl: null,
          currentScore: 80,
          correctAnswers: 4,
          level: 10,
          joinedAt: DateTime.now(),
          isReady: true,
          isFinished: true,
        ),
      ];

      final result = BattleResult(
        resultId: 'result1',
        roomId: 'room1',
        winnerId: 'user1',
        finalParticipants: participants,
        totalDurationSeconds: 600,
        completedAt: DateTime.now(),
        statistics: {},
      );

      expect(result.resultId, equals('result1'));
      expect(result.winnerId, equals('user1'));
      expect(result.finalParticipants.length, equals(2));
    });

    test('getFirstPlaceScore returns correct score', () {
      final participants = [
        BattleParticipant(
          userId: 'user1',
          displayName: '太郎',
          avatarUrl: null,
          currentScore: 100,
          correctAnswers: 5,
          level: 10,
          joinedAt: DateTime.now(),
          isReady: true,
          isFinished: true,
        ),
        BattleParticipant(
          userId: 'user2',
          displayName: '花子',
          avatarUrl: null,
          currentScore: 80,
          correctAnswers: 4,
          level: 10,
          joinedAt: DateTime.now(),
          isReady: true,
          isFinished: true,
        ),
      ];

      final result = BattleResult(
        resultId: 'result1',
        roomId: 'room1',
        winnerId: 'user1',
        finalParticipants: participants,
        totalDurationSeconds: 600,
        completedAt: DateTime.now(),
        statistics: {},
      );

      expect(result.getFirstPlaceScore(), equals(100));
    });

    test('getRanking returns sorted participants', () {
      final participants = [
        BattleParticipant(
          userId: 'user2',
          displayName: '花子',
          avatarUrl: null,
          currentScore: 80,
          correctAnswers: 4,
          level: 10,
          joinedAt: DateTime.now(),
          isReady: true,
          isFinished: true,
        ),
        BattleParticipant(
          userId: 'user1',
          displayName: '太郎',
          avatarUrl: null,
          currentScore: 100,
          correctAnswers: 5,
          level: 10,
          joinedAt: DateTime.now(),
          isReady: true,
          isFinished: true,
        ),
      ];

      final result = BattleResult(
        resultId: 'result1',
        roomId: 'room1',
        winnerId: 'user1',
        finalParticipants: participants,
        totalDurationSeconds: 600,
        completedAt: DateTime.now(),
        statistics: {},
      );

      final ranking = result.getRanking();
      expect(ranking[0].currentScore, equals(100));
      expect(ranking[1].currentScore, equals(80));
    });
  });

  group('BattleRoomStats Tests', () {
    test('BattleRoomStats can be created', () {
      final stats = BattleRoomStats(
        userId: 'user1',
        totalBattles: 10,
        victories: 7,
        defeats: 3,
        averageScore: 85.5,
        bestScore: 100,
        highestRank: 3,
      );

      expect(stats.userId, equals('user1'));
      expect(stats.totalBattles, equals(10));
      expect(stats.victories, equals(7));
    });

    test('getWinRate calculates correctly', () {
      final stats = BattleRoomStats(
        userId: 'user1',
        totalBattles: 10,
        victories: 7,
        defeats: 3,
        averageScore: 85.5,
        bestScore: 100,
        highestRank: 3,
      );

      expect(stats.getWinRate(), equals(0.7)); // 7 / 10
    });

    test('getRecord returns correct format', () {
      final stats = BattleRoomStats(
        userId: 'user1',
        totalBattles: 10,
        victories: 7,
        defeats: 3,
        averageScore: 85.5,
        bestScore: 100,
        highestRank: 3,
      );

      expect(stats.getRecord(), equals('7-3'));
    });

    test('JSON round-trip serialization', () {
      final original = BattleRoomStats(
        userId: 'user1',
        totalBattles: 10,
        victories: 7,
        defeats: 3,
        averageScore: 85.5,
        bestScore: 100,
        highestRank: 3,
      );

      final json = original.toJson();
      final fromJson = BattleRoomStats.fromJson(json);

      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.totalBattles, equals(original.totalBattles));
      expect(fromJson.victories, equals(original.victories));
      expect(fromJson.averageScore, equals(original.averageScore));
    });
  });

  group('BattleSession Tests', () {
    test('BattleSession can be created', () {
      final session = BattleSession(
        sessionId: 'session1',
        roomId: 'room1',
        currentQuestionIndex: 0,
        participantScores: {'user1': 0, 'user2': 0},
        participantCorrectAnswers: {'user1': 0, 'user2': 0},
        elapsedSeconds: 0,
        isActive: true,
      );

      expect(session.sessionId, equals('session1'));
      expect(session.roomId, equals('room1'));
      expect(session.isActive, isTrue);
    });

    test('JSON round-trip serialization', () {
      final original = BattleSession(
        sessionId: 'session1',
        roomId: 'room1',
        currentQuestionIndex: 0,
        participantScores: {'user1': 0, 'user2': 0},
        participantCorrectAnswers: {'user1': 0, 'user2': 0},
        elapsedSeconds: 0,
        isActive: true,
      );

      final json = original.toJson();
      final fromJson = BattleSession.fromJson(json);

      expect(fromJson.sessionId, equals(original.sessionId));
      expect(fromJson.roomId, equals(original.roomId));
      expect(fromJson.participantScores, equals(original.participantScores));
    });
  });
}
