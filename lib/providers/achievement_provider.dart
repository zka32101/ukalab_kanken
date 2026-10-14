import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../providers/exam_analysis_provider.dart';
import '../viewmodels/user_viewmodel.dart' as user_vm;

/// users/{uid}/profiles/{profileId} 配下のドキュメント参照
DocumentReference<Map<String, dynamic>> _profileDoc(String uid, String profileId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('profiles')
      .doc(profileId);
}

/// ユーザーのアチーブメント一覧を取得（全定義バッジと獲得状況をマージ、プロフィール単位）
final userAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return AchievementDefinition.allAchievements;

  try {
    final profileId = ref.watch(
      user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
    );
    final doc = await _profileDoc(userId, profileId).collection('achievements').get();

    final unlockedById = {
      for (final d in doc.docs) d.id: Achievement.fromJson(d.data()),
    };

    return AchievementDefinition.allAchievements
        .map((defined) => unlockedById[defined.id] ?? defined)
        .toList();
  } catch (e) {
    return AchievementDefinition.allAchievements;
  }
});

/// 新しく獲得したアチーブメントを判定
final newAchievementsProvider = FutureProvider.family<
    List<Achievement>,
    (ExamAnalysisResult, List<Achievement>)
>((ref, params) async {
  final analysis = params.$1;
  final currentAchievements = params.$2;

  return _detectNewAchievements(analysis, currentAchievements);
});

/// アチーブメント統計
class AchievementStats {
  final int totalAchievements;
  final int unlockedCount;
  final int totalPoints;
  final List<Achievement> recentlyUnlocked;

  const AchievementStats({
    required this.totalAchievements,
    required this.unlockedCount,
    required this.totalPoints,
    required this.recentlyUnlocked,
  });
}

/// アチーブメント統計プロバイダー
final achievementStatsProvider = FutureProvider<AchievementStats>((ref) async {
  final achievements = await ref.watch(userAchievementsProvider.future);

  final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
  final totalPoints =
      unlockedAchievements.fold<int>(0, (sum, a) => sum + a.points);

  // 最近獲得したアチーブメント（30日以内）
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  final recentlyUnlocked = unlockedAchievements
      .where((a) =>
          a.unlockedAt != null && a.unlockedAt!.isAfter(thirtyDaysAgo))
      .toList()
    ..sort((a, b) => (b.unlockedAt ?? DateTime(0))
        .compareTo(a.unlockedAt ?? DateTime(0)));

  return AchievementStats(
    totalAchievements: AchievementDefinition.allAchievements.length,
    unlockedCount: unlockedAchievements.length,
    totalPoints: totalPoints,
    recentlyUnlocked: recentlyUnlocked,
  );
});

/// 新しいアチーブメントを検出
Future<List<Achievement>> _detectNewAchievements(
  ExamAnalysisResult analysis,
  List<Achievement> currentAchievements,
) async {
  final newAchievements = <Achievement>[];

  // 試験成績に基づくアチーブメント
  final accuracy = analysis.overallAccuracy * 100;

  if (accuracy >= 90 && !_isUnlocked('exam_90plus', currentAchievements)) {
    newAchievements.add(
      Achievement(
        id: 'exam_90plus',
        name: '優秀者',
        description: '90点以上の成績を獲得',
        icon: '⭐',
        type: AchievementType.examScore,
        points: 100,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      ),
    );
  }

  if (accuracy >= 80 && !_isUnlocked('exam_80plus', currentAchievements)) {
    newAchievements.add(
      Achievement(
        id: 'exam_80plus',
        name: '良好',
        description: '80点以上の成績を獲得',
        icon: '✨',
        type: AchievementType.examScore,
        points: 50,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      ),
    );
  }

  if (accuracy >= 100 && !_isUnlocked('exam_perfect', currentAchievements)) {
    newAchievements.add(
      Achievement(
        id: 'exam_perfect',
        name: '完璧',
        description: '100点を獲得',
        icon: '🏆',
        type: AchievementType.examScore,
        points: 200,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      ),
    );
  }

  // カテゴリ習得に基づくアチーブメント
  for (final entry in analysis.categoryPerformance.entries) {
    final category = entry.key;
    final performance = entry.value;

    if (performance.accuracy >= 0.9) {
      if (category == 'reading' &&
          !_isUnlocked('category_reading_master', currentAchievements)) {
        newAchievements.add(
          Achievement(
            id: 'category_reading_master',
            name: '読み方マスター',
            description: '「読み」で90%以上の正答率を達成',
            icon: '📖',
            type: AchievementType.category,
            points: 75,
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          ),
        );
      }

      if (category == 'meaning' &&
          !_isUnlocked('category_meaning_master', currentAchievements)) {
        newAchievements.add(
          Achievement(
            id: 'category_meaning_master',
            name: '意味マスター',
            description: '「意味」で90%以上の正答率を達成',
            icon: '📚',
            type: AchievementType.category,
            points: 75,
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          ),
        );
      }

      if (category == 'stroke' &&
          !_isUnlocked('category_stroke_master', currentAchievements)) {
        newAchievements.add(
          Achievement(
            id: 'category_stroke_master',
            name: '筆順マスター',
            description: '「筆順」で90%以上の正答率を達成',
            icon: '✍️',
            type: AchievementType.category,
            points: 75,
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          ),
        );
      }

      if (category == 'writing' &&
          !_isUnlocked('category_writing_master', currentAchievements)) {
        newAchievements.add(
          Achievement(
            id: 'category_writing_master',
            name: '書き取りマスター',
            description: '「書き取り」で90%以上の正答率を達成',
            icon: '📝',
            type: AchievementType.category,
            points: 75,
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          ),
        );
      }

      if (category == 'usage' &&
          !_isUnlocked('category_usage_master', currentAchievements)) {
        newAchievements.add(
          Achievement(
            id: 'category_usage_master',
            name: '使い方マスター',
            description: '「使い方」で90%以上の正答率を達成',
            icon: '🈶',
            type: AchievementType.category,
            points: 75,
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  // すべてのカテゴリでマスター達成をチェック。
  // 今回の試験で解いたカテゴリだけで判定すると、1カテゴリ(例: 読み4問)の全問正解で
  // 付与されてしまうため、5カテゴリのマスター実績が(過去分+今回分で)そろったときだけ付与する。
  const masterIds = [
    'category_reading_master',
    'category_meaning_master',
    'category_stroke_master',
    'category_writing_master',
    'category_usage_master',
  ];
  final allCategoriesMastered = masterIds.every((id) =>
      _isUnlocked(id, currentAchievements) ||
      newAchievements.any((a) => a.id == id));
  if (allCategoriesMastered &&
      !_isUnlocked('category_all_master', currentAchievements)) {
    newAchievements.add(
      Achievement(
        id: 'category_all_master',
        name: 'グランドマスター',
        description: 'すべてのカテゴリで90%以上を達成',
        icon: '👑',
        type: AchievementType.category,
        points: 300,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      ),
    );
  }

  return newAchievements;
}

bool _isUnlocked(String id, List<Achievement> achievements) {
  return achievements.any((a) => a.id == id && a.isUnlocked);
}

/// アチーブメントをFirebaseに保存（プロフィール単位）
Future<void> saveAchievements(WidgetRef ref, List<Achievement> achievements) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final profileId = (await ref.read(user_vm.currentUserProvider.future))?.profileId ?? 'default';
    final batch = FirebaseFirestore.instance.batch();

    for (final achievement in achievements) {
      final docRef = _profileDoc(userId, profileId)
          .collection('achievements')
          .doc(achievement.id);

      batch.set(
        docRef,
        achievement.toJson(),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}
