import 'package:ukalab_core/ui.dart'
    show
        CoinBreakdownCard,
        CoinEvent,
        MascotStage,
        UkalabCert,
        coinProvider,
        outfitProvider,
        showMockRecordDialog;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_label.dart';
import '../models/mock_exam_modes.dart';
import '../models/achievement.dart';
import '../providers/exam_session_provider.dart';
import '../providers/oshi_provider.dart';
import '../providers/exam_analysis_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../models/learning_goal.dart';
import '../providers/learning_goal_provider.dart';
import '../models/collection_badge.dart';
import '../viewmodels/services_provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/achievement_unlock_dialog.dart';
import '../widgets/oshi_card.dart' show shareCardImageWithGate;
import '../views/core_v069_entry.dart' show MockExamAnalysisEntry;
import 'package:ukalab_core/ukalab_core.dart' show MockExamAnswer;
import 'package:kanken/widgets/text_fit.dart';

class MockExamResultScreen extends ConsumerStatefulWidget {
  final ExamSessionState session;
  final int elapsedSeconds;

  const MockExamResultScreen({
    required this.session,
    required this.elapsedSeconds,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<MockExamResultScreen> createState() =>
      _MockExamResultScreenState();
}

class _MockExamResultScreenState extends ConsumerState<MockExamResultScreen> {
  ExamSessionState get session => widget.session;
  int get elapsedSeconds => widget.elapsedSeconds;

  @override
  void initState() {
    super.initState();
    _createAndSaveAnalysis();
    _updateLeaderboardScore();
    _registerWrongAnswersForReview();
    _updateLearningGoalsProgress();
    _awardBadgeIfPassed();
    // initState 中に coinProvider の state を変える(takeRecent/grant)と Riverpod が例外を出し、
    // catch で握りつぶされてコインが一切付かなかった。ビルド後に実行する。
    Future.microtask(_awardCoinsAndReadiness);
    recordStudyActivity(ref).catchError((_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowAchievements();
    });
  }

  /// 学習コイン（模擬試験の実施・合格点）と、準備完了の装いの解放。
  /// コインは学習の成長でのみ付く。失敗しても結果画面は止めない。
  Future<void> _awardCoinsAndReadiness() async {
    try {
      final coin = ref.read(coinProvider.notifier);
      coin.takeRecent(); // 結果画面の内訳に、この試験の分だけが出るように
      await coin.grant(CoinEvent.mockDone());
      final isPassed = session.config.isPass(
          session.getCorrectAnswerCount(), session.questions.length);
      if (!isPassed) return;
      await coin.grant(CoinEvent.mockPass('kanken_level_${session.config.targetLevel}'));
      // 習得度が最高段階（Lv5＝0.8以上）なら、準備完了の装いを解放する。
      final stage = await ref.read(oshiStageProvider.future);
      if (stage == MascotStage.lv5) {
        await ref.read(outfitProvider.notifier).markReady(UkalabCert.kanjiKentei);
      }
    } catch (_) {}
  }

  /// 模擬試験で合格点を超えたときの「学習の記録カード」（本番の合格報告とは別。コインも衣装も付かない）。
  Widget _buildMockRecordButton(bool isPassed, double accuracy) {
    if (!isPassed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.ios_share),
          label: const Text('学習の記録カードを見る'),
          onPressed: () async {
            var stage = MascotStage.lv1;
            try {
              stage = await ref.read(oshiStageProvider.future);
            } catch (_) {}
            if (!mounted) return;
            await showMockRecordDialog(
              context,
              ref,
              cert: UkalabCert.kanjiKentei,
              stage: stage,
              scoreText: '正答率 ${(accuracy * 100).round()}%',
              onShare: (png) => shareCardImageWithGate(context, png),
            );
          },
        ),
      ),
    );
  }

  /// 今回貯まった学習コインの内訳（付与がなければ何も出ない）。
  Widget _buildCoinBreakdown() {
    try {
      return CoinBreakdownCard(grants: ref.watch(coinProvider).recent);
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  /// 合格ラインを超えていれば、その級の合格バッジを付与する
  Future<void> _awardBadgeIfPassed() async {
    final isPassed = session.config.isPass(
          session.getCorrectAnswerCount(), session.questions.length);
    if (!isPassed) return;

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) return;

      final level = 'LEVEL_${session.config.targetLevel}';
      final badge = CollectionBadge(
        badgeId: 'exam_pass_$level',
        name: '$level 合格バッジ',
        description: '$level の模擬試験に合格しました',
        rarity: BadgeRarity.uncommon,
        category: BadgeCategory.achievement,
        iconEmoji: '🎖️',
        requiredCount: 1,
        conditionText: '$level の模擬試験に合格',
        rewardCoins: 100,
        createdAt: DateTime.now(),
        level: level,
      );

      await ref
          .read(firestoreServiceProvider)
          .addCollectionBadge(user.uid, badge);
    } catch (e) {
      // エラーサイレント処理（他の結果画面処理と同様）
    }
  }

  Future<void> _updateLearningGoalsProgress() async {
    try {
      final analysis = await _buildAnalysisFromSession();
      final accuracy = analysis.overallAccuracy * 100;
      final score = analysis.overallAccuracy * 100;
      final questionCount = widget.session.questions.length;

      final activeGoals = await ref.read(activeLearningGoalsProvider.future);

      for (final goal in activeGoals) {
        switch (goal.type) {
          case GoalType.dailyQuestions:
            await updateGoalProgress(
              ref,
              goalId: goal.goalId,
              newValue: goal.currentValue + questionCount,
            );
            break;
          case GoalType.accuracyRate:
            if (accuracy > goal.currentValue) {
              await updateGoalProgress(
                ref,
                goalId: goal.goalId,
                newValue: accuracy.toInt(),
              );
            }
            break;
          case GoalType.examScore:
            if (score > goal.currentValue) {
              await updateGoalProgress(
                ref,
                goalId: goal.goalId,
                newValue: score.toInt(),
              );
            }
            break;
          case GoalType.weeklyStudyMinutes:
            // 今回の試験にかかった時間(分)を積み上げる。週単位でのリセットは
            // 未対応で、目標作成からの累積時間になる(今後の課題)。
            final minutesSpent = (elapsedSeconds / 60).ceil();
            if (minutesSpent > 0) {
              await updateGoalProgress(
                ref,
                goalId: goal.goalId,
                newValue: goal.currentValue + minutesSpent,
              );
            }
            break;
          case GoalType.streakDays:
            final user = await ref.read(currentUserProvider.future);
            final streak = user?.streakCount ?? 0;
            if (streak > goal.currentValue) {
              await updateGoalProgress(
                ref,
                goalId: goal.goalId,
                newValue: streak,
              );
            }
            break;
        }
      }

      ref.invalidate(activeLearningGoalsProvider);
    } catch (e) {
      // エラーサイレント処理
    }
  }

  Future<void> _registerWrongAnswersForReview() async {
    try {
      for (int i = 0; i < widget.session.questions.length; i++) {
        final question = widget.session.questions[i];
        final userAnswer = widget.session.userAnswers[i];

        if (userAnswer != question.correctAnswer) {
          await addToSpacedRepetition(
            ref,
            questionId: question.questionId,
            kanji: question.kanji,
            category: question.category.toString().split('.').last,
            question: question.question,
            options: question.options,
            correctAnswer: question.correctAnswer,
          );
        }
      }
    } catch (e) {
      // エラーサイレント処理
    }
  }

  Future<void> _checkAndShowAchievements() async {
    try {
      final currentAchievements =
          await ref.read(userAchievementsProvider.future);
      final analysis = await _buildAnalysisFromSession();

      final newAchievements =
          await _detectNewAchievements(analysis, currentAchievements);

      if (newAchievements.isNotEmpty && mounted) {
        await saveAchievements(ref, newAchievements);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AchievementUnlockDialog(
            achievements: newAchievements,
            onComplete: () {},
          ),
        );
      }
    } catch (e) {
      // エラーサイレント処理
    }
  }

  Future<ExamAnalysisResult> _buildAnalysisFromSession() async {
    final categoryStats = <String, Map<String, dynamic>>{};

    for (int i = 0; i < widget.session.questions.length; i++) {
      final question = widget.session.questions[i];
      final category = question.category.toString().split('.').last;

      if (!categoryStats.containsKey(category)) {
        categoryStats[category] = {
          'correct': 0,
          'total': 0,
        };
      }

      categoryStats[category]!['total'] += 1;
      if (widget.session.userAnswers[i] == question.correctAnswer) {
        categoryStats[category]!['correct'] += 1;
      }
    }

    final categoryPerformance = <String, CategoryPerformance>{};
    int totalCorrect = 0;
    int totalQuestions = 0;

    categoryStats.forEach((category, stats) {
      final correct = stats['correct'] as int;
      final total = stats['total'] as int;
      final accuracy = total > 0 ? correct / total : 0.0;
      final avgTime = total > 0 ? widget.elapsedSeconds / total : 0.0;

      categoryPerformance[category] = CategoryPerformance(
        category: category,
        correct: correct,
        total: total,
        accuracy: accuracy,
        averageTimePerQuestion: avgTime,
      );

      totalCorrect += correct;
      totalQuestions += total;
    });

    final overallAccuracy = totalQuestions > 0 ? totalCorrect / totalQuestions : 0.0;

    return ExamAnalysisResult(
      categoryPerformance: categoryPerformance,
      weakPoints: [],
      overallAccuracy: overallAccuracy,
      elapsedSeconds: widget.elapsedSeconds,
      examMode: widget.session.config.mode,
      analyzedAt: DateTime.now(),
    );
  }

  Future<List<Achievement>> _detectNewAchievements(
    ExamAnalysisResult analysis,
    List<Achievement> currentAchievements,
  ) async {
    final newAchievements = <Achievement>[];
    final accuracy = analysis.overallAccuracy * 100;

    // スコア段位バッジは1回の試験につき最上位1つだけ付与する
    // （90点以上と80点以上を同時に満たす場合に両方付与されないようにする）。
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
    } else if (accuracy >= 90 && !_isUnlocked('exam_90plus', currentAchievements)) {
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
    } else if (accuracy >= 80 && !_isUnlocked('exam_80plus', currentAchievements)) {
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

    const categoryMasterInfo = {
      'reading': ('category_reading_master', '読み方マスター', '「読み」で90%以上の正答率を達成', '📖', 75),
      'meaning': ('category_meaning_master', '意味マスター', '「意味」で90%以上の正答率を達成', '📚', 75),
      'stroke': ('category_stroke_master', '画数マスター', '「画数」で90%以上の正答率を達成', '✍️', 75),
      'writing': ('category_writing_master', '書き取りマスター', '「書き取り」で90%以上の正答率を達成', '📝', 75),
      'usage': ('category_usage_master', '使い方マスター', '「使い方」で90%以上の正答率を達成', '🈶', 75),
    };

    for (final entry in analysis.categoryPerformance.entries) {
      final info = categoryMasterInfo[entry.key];
      if (info == null || entry.value.accuracy < 0.9) continue;
      if (_isUnlocked(info.$1, currentAchievements)) continue;

      newAchievements.add(
        Achievement(
          id: info.$1,
          name: info.$2,
          description: info.$3,
          icon: info.$4,
          type: AchievementType.category,
          points: info.$5,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        ),
      );
    }

    // 今回解いたカテゴリだけで判定すると、1カテゴリの全問正解で付与されてしまう。
    // 5カテゴリのマスター実績が(過去分+今回分で)そろったときだけ付与する。
    final allCategoriesMastered = categoryMasterInfo.values.every((info) =>
        _isUnlocked(info.$1, currentAchievements) ||
        newAchievements.any((a) => a.id == info.$1));
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

  Future<void> _updateLeaderboardScore() async {
    try {
      final analysis = await _buildAnalysisFromSession();
      final accuracy = analysis.overallAccuracy;
      final score = (accuracy * 100).toInt();

      await updateUserScore(
        ref,
        score: score,
        examsCompleted: 1,
        averageAccuracy: accuracy,
      );
    } catch (e) {
      // エラーサイレント処理
    }
  }

  Future<void> _createAndSaveAnalysis() async {
    final categoryStats = <String, Map<String, dynamic>>{};

    for (int i = 0; i < widget.session.questions.length; i++) {
      final question = widget.session.questions[i];
      final category = question.category.toString().split('.').last;

      if (!categoryStats.containsKey(category)) {
        categoryStats[category] = {
          'correct': 0,
          'total': 0,
        };
      }

      categoryStats[category]!['total'] += 1;
      if (widget.session.userAnswers[i] == question.correctAnswer) {
        categoryStats[category]!['correct'] += 1;
      }
    }

    final categoryPerformance = <String, CategoryPerformance>{};
    int totalCorrect = 0;
    int totalQuestions = 0;

    categoryStats.forEach((category, stats) {
      final correct = stats['correct'] as int;
      final total = stats['total'] as int;
      final accuracy = total > 0 ? correct / total : 0.0;
      final avgTime = total > 0 ? widget.elapsedSeconds / total : 0.0;

      categoryPerformance[category] = CategoryPerformance(
        category: category,
        correct: correct,
        total: total,
        accuracy: accuracy,
        averageTimePerQuestion: avgTime,
      );

      totalCorrect += correct;
      totalQuestions += total;
    });

    final weakPoints = <WeakPointRecommendation>[];
    categoryPerformance.forEach((category, perf) {
      if (perf.accuracy < 0.6) {
        weakPoints.add(
          WeakPointRecommendation(
            category: category,
            accuracy: perf.accuracy,
            recommendation: '「${categoryLabel(category)}」は正答率${(perf.accuracy * 100).toStringAsFixed(1)}%です。重点的な復習が必要です。',
            priority: 1,
          ),
        );
      } else if (perf.accuracy < 0.8) {
        weakPoints.add(
          WeakPointRecommendation(
            category: category,
            accuracy: perf.accuracy,
            recommendation: '「${categoryLabel(category)}」をさらに強化できます。追加練習をお勧めします。',
            priority: 2,
          ),
        );
      }
    });

    final overallAccuracy = totalQuestions > 0 ? totalCorrect / totalQuestions : 0.0;

    final analysis = ExamAnalysisResult(
      categoryPerformance: categoryPerformance,
      weakPoints: weakPoints,
      overallAccuracy: overallAccuracy,
      elapsedSeconds: widget.elapsedSeconds,
      examMode: widget.session.config.mode,
      analyzedAt: DateTime.now(),
    );

    try {
      await saveExamAnalysis(analysis);
    } catch (e) {
      // エラーサイレント処理
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = session.getAccuracyRate();
    final isPassed = session.config.isPass(
          session.getCorrectAnswerCount(), session.questions.length);

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('試験結果'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultStatus(context, isPassed, accuracy),
              const SizedBox(height: 32),
              _buildScoreCard(context, accuracy),
              const SizedBox(height: 24),
              _buildCoinBreakdown(),
              _buildMockRecordButton(isPassed, accuracy),
              const SizedBox(height: 24),
              _buildDetailedStats(context),
              const SizedBox(height: 24),
              _buildCategoryAnalysis(context),
              const SizedBox(height: 24),
              MockExamAnalysisEntry(
                answers: [
                  for (var i = 0; i < session.questions.length; i++)
                    MockExamAnswer(
                      topicId:
                          session.questions[i].category.toString().split('.').last,
                      correct: session.userAnswers[i] ==
                          session.questions[i].correctAnswer,
                    ),
                ],
                topicLabel: categoryLabel,
              ),
              const SizedBox(height: 24),
              _buildWeakPointAnalysis(context),
              const SizedBox(height: 32),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStatus(BuildContext context, bool isPassed, double accuracy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPassed
              ? [Colors.green.shade400, Colors.green.shade700]
              : [Colors.red.shade400, Colors.red.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.cancel,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? '合格🎉' : '不合格',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '正答率: ${(accuracy * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, double accuracy) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'スコア',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildScoreTile(
                    context,
                    '${session.getCorrectAnswerCount()}',
                    '正解数',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildScoreTile(
                    context,
                    '${(accuracy * 100).toStringAsFixed(1)}%',
                    '正答率',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildScoreTile(
                    context,
                    '${session.getCorrectAnswerCount()}/${session.questions.length}',
                    '出題数',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreTile(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildDetailedStats(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '詳細情報',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              '所要時間',
              _formatTime(elapsedSeconds),
            ),
            const Divider(),
            _buildStatRow(
              '平均回答時間',
              '${(elapsedSeconds / session.questions.length).toStringAsFixed(1)}秒/問',
            ),
            const Divider(),
            _buildStatRow(
              '出題モード',
              _getModeNameJp(session.config.mode),
            ),
            const Divider(),
            _buildStatRow(
              '合否ライン',
              '${session.config.passThreshold}%以上（公式の目安）',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 2,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysis(BuildContext context) {
    final categoryStats = _calculateCategoryStats();
    if (categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'カテゴリ別分析',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...categoryStats.entries.map((entry) {
              final category = entry.key;
              final stats = entry.value;
              final accuracy = (stats['total'] ?? 0) > 0
                  ? stats['correct']! / stats['total']!
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8,
                      children: [
                        Text(
                          categoryLabel(category),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${stats['correct']}/${stats['total']} (${(accuracy * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accuracy >= 0.8
                                ? Colors.green
                                : accuracy >= 0.6
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: accuracy,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          accuracy >= 0.8
                              ? Colors.green
                              : accuracy >= 0.6
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakPointAnalysis(BuildContext context) {
    final weakPoints = _identifyWeakPoints();
    if (weakPoints.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '弱点分析',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                '🎉 すべてのカテゴリで80%以上の正答率です。素晴らしい!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '弱点分析',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...weakPoints.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              categoryLabel(point['category'] ?? ''),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        point['recommendation'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('もう一度受験'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            context.pop();
            context.pop();
          },
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.home),
          label: const Text('ホームに戻る'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            context.go('/');
          },
        ),
      ],
    );
  }

  Map<String, Map<String, int>> _calculateCategoryStats() {
    final stats = <String, Map<String, int>>{};

    for (int i = 0; i < session.questions.length; i++) {
      final question = session.questions[i];
      final category = question.category.toString().split('.').last;

      if (!stats.containsKey(category)) {
        stats[category] = {'correct': 0, 'total': 0};
      }

      stats[category]!['total'] = stats[category]!['total']! + 1;

      if (session.userAnswers[i] == question.correctAnswer) {
        stats[category]!['correct'] = stats[category]!['correct']! + 1;
      }
    }

    return stats;
  }

  List<Map<String, String>> _identifyWeakPoints() {
    final categoryStats = _calculateCategoryStats();
    final weakPoints = <Map<String, String>>[];

    categoryStats.forEach((category, stats) {
      if (stats['total']! > 0) {
        final accuracy = stats['correct']! / stats['total']!;
        if (accuracy < 0.8) {
          weakPoints.add({
            'category': category,
            'recommendation': _getRecommendation(category, accuracy),
          });
        }
      }
    });

    weakPoints.sort((a, b) => (a['category'] ?? '').compareTo(b['category'] ?? ''));
    return weakPoints;
  }

  String _getRecommendation(String category, double accuracy) {
    final percentage = (accuracy * 100).toStringAsFixed(1);
    return '「${categoryLabel(category)}」の正答率は$percentage%です。このカテゴリを重点的に復習することをお勧めします。';
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes分${secs}秒';
  }

  String _getModeNameJp(ExamMode mode) {
    const modeNames = {
      ExamMode.standardExam: '標準試験',
      ExamMode.speedExam: '速度試験',
      ExamMode.focusedExam: '集中試験',
      ExamMode.weakAreasExam: '弱点対策',
      ExamMode.randomExam: 'ランダム試験',
      ExamMode.progressiveExam: '段階式試験',
    };
    return modeNames[mode] ?? '試験';
  }
}
