import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_goal.dart';
import '../providers/learning_goal_provider.dart';
import '../viewmodels/user_viewmodel.dart';
import 'package:kanken/widgets/ukalab_emoji.dart';
import 'package:kanken/widgets/text_fit.dart';

// 各級の配当漢字数（累計）の目安。受験日から逆算した1日あたりの
// 学習ペースを提案する際の参考値として使う簡略化された値であり、
// 正式な漢検の出題範囲とは若干異なる場合がある。
const Map<String, int> _levelKanjiCount = {
  'LEVEL_10': 80,
  'LEVEL_9': 160,
  'LEVEL_8': 200,
  'LEVEL_7': 202,
  'LEVEL_6': 193,
  'LEVEL_5': 191,
  'LEVEL_4': 313,
  'LEVEL_3': 284,
  'LEVEL_2_PRE': 328,
  'LEVEL_2': 185,
  'LEVEL_1_PRE': 941,
  'LEVEL_1': 2797,
};

class LearningGoalsScreen extends ConsumerWidget {
  const LearningGoalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGoalsAsync = ref.watch(activeLearningGoalsProvider);
    final achievedGoalsAsync = ref.watch(achievedLearningGoalsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentLevel = ref.watch(currentLevelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('学習目標'),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGoalDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          currentUserAsync.when(
            data: (user) => _buildExamDateCard(
              context,
              ref,
              user?.examDate,
              currentLevel,
              activeGoalsAsync.valueOrNull,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          Text(
            '設定中の目標',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          activeGoalsAsync.when(
            data: (goals) => _buildActiveGoalsList(goals, context, ref),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('エラー: $err')),
          ),
          const SizedBox(height: 24),
          Text(
            '達成した目標',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          achievedGoalsAsync.when(
            data: (goals) => _buildAchievedGoalsList(goals, context),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('エラー: $err')),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildExamDateCard(
    BuildContext context,
    WidgetRef ref,
    DateTime? examDate,
    String currentLevel,
    List<LearningGoal>? activeGoals,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '受験日',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                CapWidth(
                  child: TextButton(
                    onPressed: () => _pickExamDate(context, ref, examDate),
                    child: Text(examDate == null ? '登録する' : '変更'),
                  ),
                ),
                if (examDate != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => updateExamDate(ref, null),
                  ),
              ],
            ),
            if (examDate == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '受験日を登録すると、残り日数に応じた学習目標を提案します',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              )
            else
              _buildExamCountdown(context, ref, examDate, currentLevel, activeGoals),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCountdown(
    BuildContext context,
    WidgetRef ref,
    DateTime examDate,
    String currentLevel,
    List<LearningGoal>? activeGoals,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(examDate.year, examDate.month, examDate.day);
    final daysLeft = target.difference(today).inDays;

    final achievementRate = _averageAchievementRate(activeGoals);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          _formatDate(examDate),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          daysLeft > 0
              ? '受験まで残り $daysLeft 日'
              : daysLeft == 0
                  ? '本日が受験日です！'
                  : '受験日を過ぎています',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        if (achievementRate != null) ...[
          const SizedBox(height: 8),
          Text(
            '現在の目標達成率: ${(achievementRate * 100).round()}%',
            style: const TextStyle(fontSize: 13),
          ),
        ],
        if (daysLeft > 0) ...[
          const SizedBox(height: 12),
          _buildSuggestedGoalButton(context, ref, currentLevel, daysLeft),
        ],
      ],
    );
  }

  double? _averageAchievementRate(List<LearningGoal>? goals) {
    if (goals == null || goals.isEmpty) return null;
    final total = goals.fold<double>(0, (sum, g) => sum + g.progressRate);
    return total / goals.length;
  }

  Widget _buildSuggestedGoalButton(
    BuildContext context,
    WidgetRef ref,
    String currentLevel,
    int daysLeft,
  ) {
    final totalKanji = _levelKanjiCount[currentLevel] ?? 80;
    final perDay = (totalKanji / daysLeft).ceil().clamp(1, totalKanji);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: Text('おすすめ目標: 1日 $perDay 問を目標に設定'),
        onPressed: () async {
          await createLearningGoal(
            ref,
            type: GoalType.dailyQuestions,
            targetValue: perDay,
            deadline: DateTime.now().add(Duration(days: daysLeft)),
          );
          ref.invalidate(activeLearningGoalsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('1日 $perDay 問の目標を設定しました')),
            );
          }
        },
      ),
    );
  }

  Future<void> _pickExamDate(
    BuildContext context,
    WidgetRef ref,
    DateTime? current,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      await updateExamDate(ref, picked);
    }
  }

  Widget _buildActiveGoalsList(
    List<LearningGoal> goals,
    BuildContext context,
    WidgetRef ref,
  ) {
    if (goals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '目標が設定されていません。右下のボタンから追加しましょう。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      children: goals.map((goal) => _buildGoalCard(goal, context, ref)).toList(),
    );
  }

  Widget _buildGoalCard(LearningGoal goal, BuildContext context, WidgetRef ref) {
    final progressColor = goal.progressRate >= 1.0
        ? Colors.green
        : goal.progressRate >= 0.5
            ? Colors.blue
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      UkalabEmoji(goal.typeIcon, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          goal.typeLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () async {
                    await deactivateLearningGoal(ref, goal.goalId);
                    ref.invalidate(activeLearningGoalsProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progressRate,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '${goal.currentValue} / ${goal.targetValue} ${goal.unit}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${goal.progressPercentage}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (goal.deadline != null) ...[
              const SizedBox(height: 4),
              Text(
                goal.isExpired ? '期限切れ' : '期限: ${_formatDate(goal.deadline!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: goal.isExpired ? Colors.red : Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievedGoalsList(List<LearningGoal> goals, BuildContext context) {
    if (goals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'まだ達成した目標はありません',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      children: goals.map((goal) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.green.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: UkalabEmoji(goal.typeIcon, size: 24),
            title: Text(
              goal.typeLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${goal.targetValue}${goal.unit}を達成'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _showCreateGoalDialog(BuildContext context, WidgetRef ref) {
    GoalType selectedType = GoalType.dailyQuestions;
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            scrollable: true,
            title: const Text('新しい目標を設定'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('目標の種類', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<GoalType>(
                                    value: selectedType,
                  isExpanded: true,
                  items: GoalType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: FitText(_getGoalTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    label: FitTitle('目標値 (${_getGoalTypeUnit(selectedType)})'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  targetController.dispose();
                  Navigator.pop(context);
                },
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final targetValue = int.tryParse(targetController.text);
                  if (targetValue == null || targetValue <= 0) return;

                  await createLearningGoal(
                    ref,
                    type: selectedType,
                    targetValue: targetValue,
                  );

                  ref.invalidate(activeLearningGoalsProvider);
                  targetController.dispose();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('作成'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getGoalTypeLabel(GoalType type) {
    switch (type) {
      case GoalType.weeklyStudyMinutes:
        return '⏱️ 週間学習時間';
      case GoalType.dailyQuestions:
        return '📝 日次問題数';
      case GoalType.accuracyRate:
        return '🎯 正答率目標';
      case GoalType.streakDays:
        return '🔥 連続学習日数';
      case GoalType.examScore:
        return '🏆 試験スコア目標';
    }
  }

  String _getGoalTypeUnit(GoalType type) {
    switch (type) {
      case GoalType.weeklyStudyMinutes:
        return '分';
      case GoalType.dailyQuestions:
        return '問';
      case GoalType.accuracyRate:
        return '%';
      case GoalType.streakDays:
        return '日';
      case GoalType.examScore:
        return '点';
    }
  }
}
