import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_exam_questions.dart';
import '../models/mock_exam.dart';
import '../models/mock_exam_modes.dart';
import '../viewmodels/services_provider.dart';

/// 模擬試験の受験履歴（users/{uid}/examResults）を新しい順に取得
final examHistoryProvider = FutureProvider<List<ExamResult>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('examResults')
      .orderBy('completedAt', descending: true)
      .limit(50)
      .get();

  return snapshot.docs
      .map((doc) => ExamResult.fromJson(doc.data()))
      .toList();
});

/// 模擬試験の母集団として1回に取得する最大件数（Firestore の limit）。
const int _kExamPoolLimit = 200;

/// Enhanced exam questions with full dataset
final enhancedExamQuestionsProvider =
    FutureProvider.family<List<EnhancedExamQuestion>, ExamConfig>(
  (ref, config) async {
    // その級で、アプリの中で作れる出題分野（四字熟語・対義語・類義語 など）。
    // 試験の分野に含まれるものだけを、Firestoreの問題に混ぜる。
    final localCategories = localExamCategoriesForLevel(config.targetLevel)
        .where(config.categories.contains)
        .toList();
    // 要求された分野がすべてアプリで作る分野なら、全問をそちらで作る。
    final onlyLocal = config.categories.every(kLocalExamCategories.contains);
    // 混ぜる割合: 作れる分野1つにつき1割、最大5割（標準試験では約半分を新しい形式にする）。
    final localShare = onlyLocal ? 1.0 : (localCategories.length * 0.1).clamp(0.0, 0.5);
    final localTarget = (config.questionCount * localShare).round();
    final local = localTarget > 0
        ? buildLocalExamQuestions(
            level: config.targetLevel,
            categories: localCategories,
            count: localTarget,
          )
        : <EnhancedExamQuestion>[];
    // Firestore の試験問題が足りない（試験問題が無い級・読み込めないとき）分を、漢字の問題
    // （読み・書き取り）から作って補う。10級・準1級・1級や、オフラインでも試験が成立する。
    Future<List<EnhancedExamQuestion>> topUp(int missing) async {
      if (missing <= 0) return const [];
      final wantsKanji = config.categories.any((c) =>
          c == ExamCategory.reading || c == ExamCategory.writing || c == ExamCategory.mixed);
      final levelString = examLevelToLevelString(config.targetLevel);
      if (!wantsKanji || levelString == null) return const [];
      try {
        final kanji = await ref
            .read(firestoreServiceProvider)
            .getQuestionsByLevel(levelString, limit: 300);
        return buildKanjiExamQuestions(
            level: config.targetLevel, kanjiQuestions: kanji, count: missing);
      } catch (_) {
        return const [];
      }
    }

    if (onlyLocal) {
      if (local.isEmpty) {
        throw Exception('この級には、選んだ分野の問題がありません');
      }
      return local;
    }

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('examQuestions')
          .where('level', isEqualTo: config.targetLevel);

      // Filter by difficulty if not all difficulties
      if (config.difficulty != ExamDifficulty.medium) {
        query = query.where(
          'difficulty',
          isEqualTo: config.difficulty.toString(),
        );
      }

      // Filter by categories if specific ones selected
      if (config.categories.length < ExamCategory.values.length) {
        query = query.where(
          'category',
          whereIn: config.categories.map((c) => c.toString()).toList(),
        );
      }

      // 無作為に選ぶための母集団を広く取る。orderBy 無しの limit は
      // ドキュメントID順の先頭しか返さないため、questionCount*1.5 件だけ
      // 取ると問題を増やしても毎回同じ問題になる。1級・カテゴリの問題は
      // 最大でも数百件なので、まとめて取ってから shuffle する。
      final limit = _kExamPoolLimit;
      final snapshot = await query.limit(limit).get();

      var questions = snapshot.docs
          .map((doc) => EnhancedExamQuestion.fromJson(doc.data()))
          .toList();

      // Randomize if configured
      if (config.randomizeOrder) {
        questions.shuffle();
      }

      // Firestoreの問題に、アプリの中で作った問題を混ぜて、要求された問題数にする。
      // それでも足りない分は、漢字の問題から作って補う。
      final fromFirestore = questions.take(config.questionCount - local.length).toList();
      final extra = await topUp(config.questionCount - local.length - fromFirestore.length);
      final merged = [...fromFirestore, ...local, ...extra];
      if (config.randomizeOrder) merged.shuffle();
      return merged;
    } catch (e) {
      // Firestoreが読めなくても、アプリの中で作れる問題と、漢字の問題から作る問題で試験を成立させる。
      final extra = await topUp(config.questionCount - local.length);
      if (local.isNotEmpty || extra.isNotEmpty) {
        final merged = [...local, ...extra];
        if (config.randomizeOrder) merged.shuffle();
        return merged;
      }
      throw Exception('Failed to load enhanced exam questions: $e');
    }
  },
);

/// Weak area questions (adaptive based on user performance)
final weakAreaQuestionsProvider = FutureProvider.family<
    List<EnhancedExamQuestion>,
    ({String userId, int examLevel})>(
  (ref, params) async {
    try {
      // Get user's weak areas from their history
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(params.userId)
          .collection('weakAreas')
          .get();

      final weakAreas = userSnapshot.docs
          .map((doc) => doc['category'] as String?)
          .whereType<String>()
          .toList();

      // 弱点カテゴリ・難易度で絞り込むが、現状の問題データ量
      // （1級につき20問程度）では「hard」に限定すると数問しか
      // 残らず試験が成立しないため、難易度は絞らず級とカテゴリのみで
      // 抽出する（苦手カテゴリを優先しつつ、母数を確保する）。
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('examQuestions')
          .where('level', isEqualTo: params.examLevel);

      if (weakAreas.isNotEmpty) {
        query = query.where('category', whereIn: weakAreas);
      }

      final snapshot = await query.limit(100).get();

      var questions = snapshot.docs
          .map((doc) => EnhancedExamQuestion.fromJson(doc.data()))
          .toList();

      questions.shuffle();
      return questions.take(20).toList();
    } catch (e) {
      throw Exception('Failed to load weak area questions: $e');
    }
  },
);

/// Progressive exam questions (difficulty increases with correct answers)
final progressiveExamQuestionsProvider =
    FutureProvider.family<List<EnhancedExamQuestion>, int>(
  (ref, examLevel) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('examQuestions')
          .where('level', isEqualTo: examLevel)
          .limit(200)
          .get();

      final questions = snapshot.docs
          .map((doc) => EnhancedExamQuestion.fromJson(doc.data()))
          .toList();

      // Sort by difficulty for progressive ordering
      questions.sort((a, b) {
        final difficultyOrder = {
          'ExamDifficulty.easy': 0,
          'ExamDifficulty.medium': 1,
          'ExamDifficulty.hard': 2,
          'ExamDifficulty.veryHard': 3,
        };
        return (difficultyOrder[a.difficulty.toString()] ?? 0)
            .compareTo(difficultyOrder[b.difficulty.toString()] ?? 0);
      });

      return questions.take(20).toList();
    } catch (e) {
      throw Exception('Failed to load progressive exam questions: $e');
    }
  },
);

/// Exam statistics with detailed breakdowns
final detailedExamStatisticsProvider =
    FutureProvider.family<DetailedExamStatistics, String>(
  (ref, userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('examStatistics')
          .doc('detailed')
          .get();

      if (!snapshot.exists) {
        return DetailedExamStatistics.empty(userId);
      }

      return DetailedExamStatistics.fromJson(snapshot.data() ?? {});
    } catch (e) {
      throw Exception('Failed to load detailed exam statistics: $e');
    }
  },
);

/// Category-wise exam results
final categoryExamResultsProvider = FutureProvider.family<
    Map<String, dynamic>,
    ({String userId, int examLevel})>(
  (ref, params) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(params.userId)
          .collection('examResults')
          .where('examLevel', isEqualTo: params.examLevel)
          .get();

      final results = <String, dynamic>{};

      for (final category in ExamCategory.values) {
        int total = 0;
        int correct = 0;
        double avgTime = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final answers = (data['answers'] as List?)
              ?.map((a) => a as Map<String, dynamic>)
              .toList() ?? [];

          for (final answer in answers) {
            if (answer['category'] == category.toString()) {
              total++;
              if ((answer['isCorrect'] as bool?) == true) {
                correct++;
              }
              avgTime += (answer['timeSpent'] as num?)?.toDouble() ?? 0;
            }
          }
        }

        if (total > 0) {
          results[category.toString()] = {
            'total': total,
            'correct': correct,
            'accuracy': (correct / total * 100).toStringAsFixed(1),
            'averageTime': (avgTime / total).toStringAsFixed(1),
          };
        }
      }

      return results;
    } catch (e) {
      throw Exception('Failed to load category exam results: $e');
    }
  },
);

/// Detailed exam statistics model
class DetailedExamStatistics {
  final String userId;
  final int totalExamsTaken;
  final int totalPassed;
  final double averageAccuracy;
  final int bestScore;
  final int worstScore;
  final Map<String, dynamic> levelStatistics;
  final Map<String, dynamic> categoryStatistics;
  final List<Map<String, dynamic>> recentExams;
  final double averageTimePerQuestion;

  DetailedExamStatistics({
    required this.userId,
    required this.totalExamsTaken,
    required this.totalPassed,
    required this.averageAccuracy,
    required this.bestScore,
    required this.worstScore,
    required this.levelStatistics,
    required this.categoryStatistics,
    required this.recentExams,
    required this.averageTimePerQuestion,
  });

  factory DetailedExamStatistics.empty(String userId) => DetailedExamStatistics(
    userId: userId,
    totalExamsTaken: 0,
    totalPassed: 0,
    averageAccuracy: 0.0,
    bestScore: 0,
    worstScore: 0,
    levelStatistics: {},
    categoryStatistics: {},
    recentExams: [],
    averageTimePerQuestion: 0.0,
  );

  factory DetailedExamStatistics.fromJson(Map<String, dynamic> json) =>
    DetailedExamStatistics(
      userId: json['userId'] as String? ?? '',
      totalExamsTaken: json['totalExamsTaken'] as int? ?? 0,
      totalPassed: json['totalPassed'] as int? ?? 0,
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
      bestScore: json['bestScore'] as int? ?? 0,
      worstScore: json['worstScore'] as int? ?? 0,
      levelStatistics: json['levelStatistics'] as Map<String, dynamic>? ?? {},
      categoryStatistics: json['categoryStatistics'] as Map<String, dynamic>? ?? {},
      recentExams: (json['recentExams'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      averageTimePerQuestion:
        (json['averageTimePerQuestion'] as num?)?.toDouble() ?? 0.0,
    );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'totalExamsTaken': totalExamsTaken,
    'totalPassed': totalPassed,
    'averageAccuracy': averageAccuracy,
    'bestScore': bestScore,
    'worstScore': worstScore,
    'levelStatistics': levelStatistics,
    'categoryStatistics': categoryStatistics,
    'recentExams': recentExams,
    'averageTimePerQuestion': averageTimePerQuestion,
  };
}
