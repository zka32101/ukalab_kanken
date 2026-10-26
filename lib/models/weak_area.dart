import 'package:cloud_firestore/cloud_firestore.dart';

/// 苦手分野レベル（分析結果）
enum WeakLevel {
  excellent,  // 得意（90%以上）
  good,       // 良好（70-89%）
  normal,     // 普通（50-69%）
  weak,       // 苦手（30-49%）
  veryWeak,   // 非常に苦手（0-29%）
}

/// 苦手分野データ
class WeakArea {
  final String categoryId;
  final String categoryName;
  final int totalAttempts;    // 総出題数
  final int correctAnswers;   // 正解数
  final double accuracyRate;  // 正答率（0.0-1.0）
  final WeakLevel level;
  final int recentStreakDays; // 連続学習日数
  final DateTime lastAttemptAt;
  final List<String> problematicKanjiIds; // 苦手な漢字 ID リスト

  const WeakArea({
    required this.categoryId,
    required this.categoryName,
    required this.totalAttempts,
    required this.correctAnswers,
    required this.accuracyRate,
    required this.level,
    required this.recentStreakDays,
    required this.lastAttemptAt,
    this.problematicKanjiIds = const [],
  });

  /// 正答率を文字列で表示（パーセント）
  String getAccuracyPercentage() {
    return '${(accuracyRate * 100).toStringAsFixed(1)}%';
  }

  /// 苦手レベルのラベル
  String getLevelLabel() {
    switch (level) {
      case WeakLevel.excellent:
        return '優秀';
      case WeakLevel.good:
        return '良好';
      case WeakLevel.normal:
        return '普通';
      case WeakLevel.weak:
        return '苦手';
      case WeakLevel.veryWeak:
        return '要改善';
    }
  }

  /// 苦手レベルの絵文字
  String getLevelEmoji() {
    switch (level) {
      case WeakLevel.excellent:
        return '⭐⭐⭐';
      case WeakLevel.good:
        return '⭐⭐';
      case WeakLevel.normal:
        return '⭐';
      case WeakLevel.weak:
        return '⚠️';
      case WeakLevel.veryWeak:
        return '🔴';
    }
  }

  /// 改善を要する判定
  bool get needsImprovement => level.index >= WeakLevel.weak.index;

  /// 推奨学習頻度（日数）
  int getRecommendedFrequency() {
    switch (level) {
      case WeakLevel.excellent:
        return 7;  // 1週間
      case WeakLevel.good:
        return 14; // 2週間
      case WeakLevel.normal:
        return 3;  // 3日
      case WeakLevel.weak:
        return 1;  // 毎日
      case WeakLevel.veryWeak:
        return 1;  // 毎日（複数回推奨）
    }
  }

  /// 推奨出題数
  int getRecommendedQuestionCount() {
    switch (level) {
      case WeakLevel.excellent:
        return 10;
      case WeakLevel.good:
        return 5;
      case WeakLevel.normal:
        return 15;
      case WeakLevel.weak:
        return 20;
      case WeakLevel.veryWeak:
        return 25;
    }
  }

  /// JSON からのデシリアライズ
  factory WeakArea.fromJson(Map<String, dynamic> json) {
    final accuracyRate = (json['accuracyRate'] as num?)?.toDouble() ?? 0.0;
    final hasAccuracyRate = json.containsKey('accuracyRate');

    return WeakArea(
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? 'Unknown',
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      accuracyRate: accuracyRate,
      level: hasAccuracyRate ? weakLevelFromAccuracy(accuracyRate) : WeakLevel.excellent,
      recentStreakDays: json['recentStreakDays'] as int? ?? 0,
      lastAttemptAt: json['lastAttemptAt'] is Timestamp
          ? (json['lastAttemptAt'] as Timestamp).toDate()
          : DateTime.now(),
      problematicKanjiIds: List<String>.from(
        json['problematicKanjiIds'] as List? ?? [],
      ),
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'categoryName': categoryName,
    'totalAttempts': totalAttempts,
    'correctAnswers': correctAnswers,
    'accuracyRate': accuracyRate,
    'recentStreakDays': recentStreakDays,
    'lastAttemptAt': Timestamp.fromDate(lastAttemptAt),
    'problematicKanjiIds': problematicKanjiIds,
  };

  @override
  String toString() =>
      'WeakArea(category: $categoryName, accuracy: ${getAccuracyPercentage()}, level: ${getLevelLabel()})';
}

/// 正答率から苦手レベルを判定
WeakLevel weakLevelFromAccuracy(double accuracy) {
  if (accuracy >= 0.9) return WeakLevel.excellent;
  if (accuracy >= 0.7) return WeakLevel.good;
  if (accuracy >= 0.5) return WeakLevel.normal;
  if (accuracy >= 0.3) return WeakLevel.weak;
  return WeakLevel.veryWeak;
}

/// 苦手分野分析データ
class WeakAreaAnalysis {
  final List<WeakArea> allAreas;
  final List<WeakArea> weakAreas;        // 苦手な分野（改善要）
  final double overallAccuracy;
  final DateTime analyzedAt;

  WeakAreaAnalysis({
    required this.allAreas,
    required this.overallAccuracy,
    required this.analyzedAt,
  }) : weakAreas = allAreas.where((area) => area.needsImprovement).toList();

  /// 最も苦手な分野
  WeakArea? getWorstArea() {
    if (weakAreas.isEmpty) return null;
    return weakAreas.reduce((a, b) => a.accuracyRate < b.accuracyRate ? a : b);
  }

  /// 分野数別の統計
  int get totalCategories => allAreas.length;
  int get weakCategoryCount => weakAreas.length;

  /// 改善度合い（全体の何%が苦手か）
  double get weakPercentage {
    if (allAreas.isEmpty) return 0.0;
    return weakAreas.length / allAreas.length;
  }

  @override
  String toString() =>
      'WeakAreaAnalysis(total: $totalCategories, weak: $weakCategoryCount, overall: ${(overallAccuracy * 100).toStringAsFixed(1)}%)';
}
