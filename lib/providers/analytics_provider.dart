import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/exam_prep_data.dart' show historyProvider;
import '../models/analytics.dart';
import '../services/local_analytics.dart';
import '../views/core_features_entry.dart' show kankenLevelLabel;

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

/// 学習分析データ。解答の記録は端末内にしかないので、履歴から集計する。
final userLearningAnalyticsProvider =
    FutureProvider<LearningAnalytics?>((ref) async {
  return analyticsFromHistory(ref.watch(historyProvider));
});

/// 成長データ（過去30日）。端末内の履歴から集計する。
final userGrowthDataProvider = FutureProvider<List<GrowthData>>((ref) async {
  return growthFromHistory(ref.watch(historyProvider));
});

/// 級ごとの学習トレンド。端末内の履歴から作る。
final userLearningTrendsProvider =
    FutureProvider<List<LearningTrend>>((ref) async {
  return trendsFromHistory(ref.watch(historyProvider),
      nameOf: kankenLevelLabel);
});

/// 学習効率。端末内の履歴から作る。
final userStudyEfficiencyProvider =
    FutureProvider<StudyEfficiency?>((ref) async {
  return efficiencyFromHistory(ref.watch(historyProvider));
});
