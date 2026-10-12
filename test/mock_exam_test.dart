import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/mock_exam.dart';

void main() {
  group('ExamQuestion Tests', () {
    test('ExamQuestion can be created with all fields', () {
      final question = ExamQuestion(
        questionId: 'q1',
        kanji: '漢',
        questionType: 'reading',
        question: 'この漢字の読み方は？',
        options: ['かん', 'から', 'かみ', 'かぎ'],
        correctAnswer: 'かん',
        explanation: '正しい読み方は「かん」です',
        level: 10,
      );

      expect(question.questionId, equals('q1'));
      expect(question.kanji, equals('漢'));
      expect(question.options.length, equals(4));
      expect(question.correctAnswer, equals('かん'));
    });

    test('JSON round-trip serialization', () {
      final original = ExamQuestion(
        questionId: 'q1',
        kanji: '漢',
        questionType: 'reading',
        question: 'この漢字の読み方は？',
        options: ['かん', 'から', 'かみ', 'かぎ'],
        correctAnswer: 'かん',
        explanation: '正しい読み方は「かん」です',
        level: 10,
      );

      final json = original.toJson();
      final fromJson = ExamQuestion.fromJson(json);

      expect(fromJson.questionId, equals(original.questionId));
      expect(fromJson.kanji, equals(original.kanji));
      expect(fromJson.correctAnswer, equals(original.correctAnswer));
      expect(fromJson.level, equals(original.level));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = {
        'questionId': 'q1',
        'kanji': '漢',
      };

      final question = ExamQuestion.fromJson(json);
      expect(question.questionId, equals('q1'));
      expect(question.questionType, equals('reading'));
      expect(question.options, isEmpty);
      expect(question.level, equals(10));
    });
  });

  group('UserAnswer Tests', () {
    test('UserAnswer can be created', () {
      final answer = UserAnswer(
        questionIndex: 0,
        selectedAnswer: 'かん',
        isCorrect: true,
        timeSpent: 45,
      );

      expect(answer.questionIndex, equals(0));
      expect(answer.selectedAnswer, equals('かん'));
      expect(answer.isCorrect, isTrue);
      expect(answer.timeSpent, equals(45));
    });

    test('JSON round-trip serialization', () {
      final original = UserAnswer(
        questionIndex: 0,
        selectedAnswer: 'かん',
        isCorrect: true,
        timeSpent: 45,
      );

      final json = original.toJson();
      final fromJson = UserAnswer.fromJson(json);

      expect(fromJson.questionIndex, equals(original.questionIndex));
      expect(fromJson.selectedAnswer, equals(original.selectedAnswer));
      expect(fromJson.isCorrect, equals(original.isCorrect));
      expect(fromJson.timeSpent, equals(original.timeSpent));
    });
  });

  group('ExamResult Tests', () {
    test('ExamResult can be created with all fields', () {
      final completedAt = DateTime(2026, 9, 13);
      final result = ExamResult(
        resultId: 'r1',
        userId: 'user1',
        examSessionId: 's1',
        examLevel: 10,
        totalQuestions: 50,
        correctAnswers: 40,
        accuracyRate: 0.8,
        totalTimeSeconds: 1800,
        answers: [],
        completedAt: completedAt,
        isPassed: true,
        estimatedRank: 5,
        categoryScores: {},
      );

      expect(result.resultId, equals('r1'));
      expect(result.examLevel, equals(10));
      expect(result.correctAnswers, equals(40));
      expect(result.accuracyRate, equals(0.8));
    });

    test('calculateScore returns correct score', () {
      final result = ExamResult(
        resultId: 'r1',
        userId: 'user1',
        examSessionId: 's1',
        examLevel: 10,
        totalQuestions: 50,
        correctAnswers: 40,
        accuracyRate: 0.8,
        totalTimeSeconds: 1800,
        answers: [],
        completedAt: DateTime.now(),
        isPassed: true,
        estimatedRank: 5,
        categoryScores: {},
      );

      expect(result.calculateScore(), equals(160)); // 0.8 * 200
    });

    test('getPassStatus returns correct status', () {
      final passedResult = ExamResult(
        resultId: 'r1',
        userId: 'user1',
        examSessionId: 's1',
        examLevel: 10,
        totalQuestions: 50,
        correctAnswers: 30,
        accuracyRate: 0.6,
        totalTimeSeconds: 1800,
        answers: [],
        completedAt: DateTime.now(),
        isPassed: true,
        estimatedRank: 0,
        categoryScores: {},
      );

      final failedResult = ExamResult(
        resultId: 'r2',
        userId: 'user1',
        examSessionId: 's2',
        examLevel: 10,
        totalQuestions: 50,
        correctAnswers: 25,
        accuracyRate: 0.5,
        totalTimeSeconds: 1800,
        answers: [],
        completedAt: DateTime.now(),
        isPassed: false,
        estimatedRank: 0,
        categoryScores: {},
      );

      expect(passedResult.getPassStatus(), isTrue);
      expect(failedResult.getPassStatus(), isFalse);
    });

    test('getAverageTimePerQuestion calculates correctly', () {
      final result = ExamResult(
        resultId: 'r1',
        userId: 'user1',
        examSessionId: 's1',
        examLevel: 10,
        totalQuestions: 50,
        correctAnswers: 40,
        accuracyRate: 0.8,
        totalTimeSeconds: 1500,
        answers: [],
        completedAt: DateTime.now(),
        isPassed: true,
        estimatedRank: 0,
        categoryScores: {},
      );

      expect(result.getAverageTimePerQuestion(), equals(30)); // 1500 / 50
    });

    test('JSON round-trip serialization', () {
      final completedAt = DateTime(2026, 9, 13);
      final original = ExamResult(
        resultId: 'r1',
        userId: 'user1',
        examSessionId: 's1',
        examLevel: 10,
        totalQuestions: 50,
        correctAnswers: 40,
        accuracyRate: 0.8,
        totalTimeSeconds: 1800,
        answers: [],
        completedAt: completedAt,
        isPassed: true,
        estimatedRank: 5,
        categoryScores: {},
      );

      final json = original.toJson();
      final fromJson = ExamResult.fromJson(json);

      expect(fromJson.resultId, equals(original.resultId));
      expect(fromJson.examLevel, equals(original.examLevel));
      expect(fromJson.correctAnswers, equals(original.correctAnswers));
      expect(fromJson.isPassed, equals(original.isPassed));
    });
  });

  group('ExamSession Tests', () {
    test('ExamSession can be created', () {
      final questions = [
        ExamQuestion(
          questionId: 'q1',
          kanji: '漢',
          questionType: 'reading',
          question: 'この漢字の読み方は？',
          options: ['かん', 'から', 'かみ', 'かぎ'],
          correctAnswer: 'かん',
          explanation: '正しい読み方は「かん」です',
          level: 10,
        ),
      ];

      final session = ExamSession(
        sessionId: 's1',
        userId: 'user1',
        examLevel: 10,
        questions: questions,
        currentQuestionIndex: 0,
        userAnswers: [],
        startedAt: DateTime.now(),
        totalTimeSeconds: 1800,
        elapsedSeconds: 0,
        isCompleted: false,
      );

      expect(session.sessionId, equals('s1'));
      expect(session.questions.length, equals(1));
      expect(session.getCurrentQuestion(), isNotNull);
    });

    test('getProgressPercentage calculates correctly', () {
      final questions = [
        ExamQuestion(
          questionId: 'q1',
          kanji: '漢',
          questionType: 'reading',
          question: '？',
          options: ['a', 'b'],
          correctAnswer: 'a',
          explanation: '',
          level: 10,
        ),
        ExamQuestion(
          questionId: 'q2',
          kanji: '字',
          questionType: 'reading',
          question: '？',
          options: ['a', 'b'],
          correctAnswer: 'a',
          explanation: '',
          level: 10,
        ),
      ];

      final session = ExamSession(
        sessionId: 's1',
        userId: 'user1',
        examLevel: 10,
        questions: questions,
        currentQuestionIndex: 1,
        userAnswers: [],
        startedAt: DateTime.now(),
        totalTimeSeconds: 1800,
        elapsedSeconds: 300,
        isCompleted: false,
      );

      expect(session.getProgressPercentage(), equals(0.5));
    });

    test('getRemainingTime calculates correctly', () {
      final session = ExamSession(
        sessionId: 's1',
        userId: 'user1',
        examLevel: 10,
        questions: [],
        currentQuestionIndex: 0,
        userAnswers: [],
        startedAt: DateTime.now(),
        totalTimeSeconds: 1800,
        elapsedSeconds: 600,
        isCompleted: false,
      );

      expect(session.getRemainingTime(), equals(1200)); // 1800 - 600
    });

    test('isTimeUp returns correct status', () {
      final notTimeUp = ExamSession(
        sessionId: 's1',
        userId: 'user1',
        examLevel: 10,
        questions: [],
        currentQuestionIndex: 0,
        userAnswers: [],
        startedAt: DateTime.now(),
        totalTimeSeconds: 1800,
        elapsedSeconds: 600,
        isCompleted: false,
      );

      final timeUp = ExamSession(
        sessionId: 's2',
        userId: 'user1',
        examLevel: 10,
        questions: [],
        currentQuestionIndex: 0,
        userAnswers: [],
        startedAt: DateTime.now(),
        totalTimeSeconds: 1800,
        elapsedSeconds: 1800,
        isCompleted: true,
      );

      expect(notTimeUp.isTimeUp(), isFalse);
      expect(timeUp.isTimeUp(), isTrue);
    });
  });

  group('ExamStatistics Tests', () {
    test('ExamStatistics can be created', () {
      final stats = ExamStatistics(
        userId: 'user1',
        totalExamsTaken: 10,
        totalPassed: 8,
        averageAccuracy: 0.75,
        bestScore: 180,
        worstScore: 100,
        levelStatistics: {},
      );

      expect(stats.userId, equals('user1'));
      expect(stats.totalExamsTaken, equals(10));
      expect(stats.totalPassed, equals(8));
    });

    test('getPassRate calculates correctly', () {
      final stats = ExamStatistics(
        userId: 'user1',
        totalExamsTaken: 10,
        totalPassed: 8,
        averageAccuracy: 0.75,
        bestScore: 180,
        worstScore: 100,
        levelStatistics: {},
      );

      expect(stats.getPassRate(), equals(0.8)); // 8 / 10
    });

    test('getPassRate returns 0 when no exams taken', () {
      final stats = ExamStatistics(
        userId: 'user1',
        totalExamsTaken: 0,
        totalPassed: 0,
        averageAccuracy: 0.0,
        bestScore: 0,
        worstScore: 0,
        levelStatistics: {},
      );

      expect(stats.getPassRate(), equals(0.0));
    });

    test('JSON round-trip serialization', () {
      final original = ExamStatistics(
        userId: 'user1',
        totalExamsTaken: 10,
        totalPassed: 8,
        averageAccuracy: 0.75,
        bestScore: 180,
        worstScore: 100,
        levelStatistics: {},
      );

      final json = original.toJson();
      final fromJson = ExamStatistics.fromJson(json);

      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.totalExamsTaken, equals(original.totalExamsTaken));
      expect(fromJson.totalPassed, equals(original.totalPassed));
      expect(fromJson.averageAccuracy, equals(original.averageAccuracy));
    });
  });
}
