import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_recommendation.dart';
import '../viewmodels/user_viewmodel.dart' as user_vm;
import 'weak_area_provider.dart';

/// users/{uid}/profiles/{profileId} 配下のドキュメント参照
DocumentReference<Map<String, dynamic>> _profileDoc(String uid, String profileId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('profiles')
      .doc(profileId);
}

/// 学習推奨プランを生成
final learningPlanProvider = FutureProvider<LearningPlan>((ref) async {
  final analysis = await ref.watch(weakAreaAnalysisProvider.future);

  final recommendations = <LearningRecommendation>[];

  for (final weakArea in analysis.weakAreas) {
    // 優先度を決定（正答率に基づく）
    RecommendationPriority priority;
    if (weakArea.accuracyRate < 0.3) {
      priority = RecommendationPriority.critical;
    } else if (weakArea.accuracyRate < 0.5) {
      priority = RecommendationPriority.high;
    } else if (weakArea.accuracyRate < 0.7) {
      priority = RecommendationPriority.medium;
    } else {
      priority = RecommendationPriority.low;
    }

    // 難易度を決定
    DifficultyLevel difficulty;
    if (weakArea.totalAttempts < 5) {
      difficulty = DifficultyLevel.basic;
    } else if (weakArea.totalAttempts < 20) {
      difficulty = DifficultyLevel.standard;
    } else {
      difficulty = DifficultyLevel.advanced;
    }

    // 推奨理由を生成
    String reason;
    if (priority == RecommendationPriority.critical) {
      reason = '正答率が${weakArea.getAccuracyPercentage()}と低いため、基礎から復習が必要です。';
    } else if (priority == RecommendationPriority.high) {
      reason = '正答率が${weakArea.getAccuracyPercentage()}であり、継続的な学習が必要です。';
    } else {
      reason = '正答率が${weakArea.getAccuracyPercentage()}です。さらに深い理解のため応用問題に挑戦してください。';
    }

    // 推奨日数を計算（優先度と正答率から）
    int estimatedDays;
    switch (priority) {
      case RecommendationPriority.critical:
        estimatedDays = 14; // 2週間
        break;
      case RecommendationPriority.high:
        estimatedDays = 10; // 10日
        break;
      case RecommendationPriority.medium:
        estimatedDays = 7;  // 1週間
        break;
      case RecommendationPriority.low:
        estimatedDays = 5;  // 5日
        break;
    }

    final recommendation = LearningRecommendation(
      recommendationId: weakArea.categoryId,
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      targetCategoryId: weakArea.categoryId,
      targetCategoryName: weakArea.categoryName,
      priority: priority,
      difficulty: difficulty,
      reason: reason,
      recommendedDailyQuestions: weakArea.getRecommendedQuestionCount(),
      estimatedDaysToImprove: estimatedDays,
      createdAt: DateTime.now(),
    );

    recommendations.add(recommendation);
  }

  // 優先度でソート（critical → low）
  recommendations.sort((a, b) => b.priority.index.compareTo(a.priority.index));

  return LearningPlan(
    recommendations: recommendations,
    generatedAt: DateTime.now(),
  );
});

/// 学習推奨を取得（Firestore から、プロフィール単位）
final activeLearningRecommendationsProvider = FutureProvider<List<LearningRecommendation>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final profileId = ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );

  final snapshot = await _profileDoc(userId, profileId)
      .collection('learningRecommendations')
      .where('isCompleted', isEqualTo: false)
      .orderBy('priority')
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => LearningRecommendation.fromJson(doc.data()))
      .toList();
});

/// 完了した推奨を取得（プロフィール単位）
final completedLearningRecommendationsProvider = FutureProvider<List<LearningRecommendation>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final profileId = ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );

  final snapshot = await _profileDoc(userId, profileId)
      .collection('learningRecommendations')
      .where('isCompleted', isEqualTo: true)
      .orderBy('completedAt', descending: true)
      .limit(10)
      .get();

  return snapshot.docs
      .map((doc) => LearningRecommendation.fromJson(doc.data()))
      .toList();
});

/// 学習推奨プロバイダー State
class LearningPlanState {
  final LearningPlan? currentPlan;
  final bool isLoading;
  final String? error;

  LearningPlanState({
    this.currentPlan,
    this.isLoading = false,
    this.error,
  });

  LearningPlanState copyWith({
    LearningPlan? currentPlan,
    bool? isLoading,
    String? error,
  }) {
    return LearningPlanState(
      currentPlan: currentPlan ?? this.currentPlan,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 学習推奨管理の StateNotifier（プロフィール単位）
class LearningPlanNotifier extends StateNotifier<LearningPlanState> {
  LearningPlanNotifier(this._ref) : super(LearningPlanState());

  final Ref _ref;
  final _auth = FirebaseAuth.instance;

  Future<String> _currentProfileId() async {
    final user = await _ref.read(user_vm.currentUserProvider.future);
    return user?.profileId ?? 'default';
  }

  /// 推奨を Firestore に保存
  Future<void> saveLearningPlan(LearningPlan plan) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final profileId = await _currentProfileId();
      final batch = FirebaseFirestore.instance.batch();

      for (final recommendation in plan.recommendations) {
        final docRef = _profileDoc(currentUser.uid, profileId)
            .collection('learningRecommendations')
            .doc(recommendation.recommendationId);

        batch.set(docRef, recommendation.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
      state = state.copyWith(currentPlan: plan, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '学習プランの保存に失敗しました: $e',
      );
    }
  }

  /// 推奨の進捗を更新
  Future<void> updateRecommendationProgress({
    required String recommendationId,
    required double progressAccuracy,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final profileId = await _currentProfileId();
      await _profileDoc(currentUser.uid, profileId)
          .collection('learningRecommendations')
          .doc(recommendationId)
          .update({
        'progressAccuracy': progressAccuracy,
      });
    } catch (e) {
      state = state.copyWith(
        error: '進捗の更新に失敗しました: $e',
      );
    }
  }

  /// 推奨を完了
  Future<void> completeRecommendation(String recommendationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final profileId = await _currentProfileId();
      await _profileDoc(currentUser.uid, profileId)
          .collection('learningRecommendations')
          .doc(recommendationId)
          .update({
        'isCompleted': true,
        'completedAt': Timestamp.now(),
      });
    } catch (e) {
      state = state.copyWith(
        error: '推奨の完了に失敗しました: $e',
      );
    }
  }

  /// 推奨を削除
  Future<void> deleteRecommendation(String recommendationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final profileId = await _currentProfileId();
      await _profileDoc(currentUser.uid, profileId)
          .collection('learningRecommendations')
          .doc(recommendationId)
          .delete();
    } catch (e) {
      state = state.copyWith(
        error: '推奨の削除に失敗しました: $e',
      );
    }
  }
}

/// 学習推奨管理プロバイダー
final learningPlanNotifierProvider = StateNotifierProvider<LearningPlanNotifier, LearningPlanState>((ref) {
  return LearningPlanNotifier(ref);
});
