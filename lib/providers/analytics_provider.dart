import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/exam_prep_data.dart' show historyProvider;
import '../models/analytics.dart';
import '../services/local_analytics.dart';
import '../viewmodels/user_viewmodel.dart' as user_vm;

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.currentUser?.uid;
});

/// 現在のプロフィールIDを取得
final _currentProfileIdProvider = Provider<String>((ref) {
  return ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );
});

/// users/{uid}/profiles/{profileId} 配下のドキュメント参照
DocumentReference<Map<String, dynamic>> _profileDoc(String uid, String profileId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('profiles')
      .doc(profileId);
}

/// 学習分析データ。解答の記録は端末内にしかないので、履歴から集計する。
final userLearningAnalyticsProvider =
    FutureProvider<LearningAnalytics?>((ref) async {
  return analyticsFromHistory(ref.watch(historyProvider));
});

/// 成長データ（過去30日）。端末内の履歴から集計する。
final userGrowthDataProvider = FutureProvider<List<GrowthData>>((ref) async {
  return growthFromHistory(ref.watch(historyProvider));
});

/// ユーザーの学習トレンド（プロフィール単位）
final userLearningTrendsProvider =
    FutureProvider<List<LearningTrend>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final profileId = ref.watch(_currentProfileIdProvider);
  final querySnapshot = await _profileDoc(userId, profileId)
      .collection('learningTrends')
      .orderBy('averageTrend', descending: true)
      .get();

  return querySnapshot.docs
      .map((doc) => LearningTrend.fromJson(doc.data()))
      .toList();
});

/// ユーザーの学習効率（プロフィール単位）
final userStudyEfficiencyProvider =
    FutureProvider<StudyEfficiency?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final profileId = ref.watch(_currentProfileIdProvider);
  final doc = await _profileDoc(userId, profileId)
      .collection('studyEfficiency')
      .doc('current')
      .get();

  if (!doc.exists) return null;

  return StudyEfficiency.fromJson(doc.data() ?? {});
});

// 学習目標(LearningGoal)の作成・一覧・達成管理は
// lib/providers/learning_goal_provider.dart + lib/models/learning_goal.dart
// (learning_goals_screen.dart が使う実装)に一本化した。
// 以前ここにあった userLearningGoalsProvider / AnalyticsDashboardState /
// AnalyticsDashboardNotifier / analyticsDashboardProvider は、
// 同じFirestoreコレクション(users/{uid}/learningGoals)を別スキーマの
// LearningGoal(lib/models/analytics.dart)で読み書きしており、
// 「学習目標を設定しても一覧に出てこない・保存したはずが消える」
// 不具合の原因になっていたため削除した。
