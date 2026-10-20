import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// カテゴリ別進捗バー
class CategoryProgressBar extends StatelessWidget {
  final String category;
  final double progress; // 0.0 - 1.0
  final int correctCount;
  final int totalCount;

  const CategoryProgressBar({
    required this.category,
    required this.progress,
    required this.correctCount,
    required this.totalCount,
    Key? key,
  }) : super(key: key);

  Color _getProgressColor() {
    if (progress >= 0.9) return Colors.green;
    if (progress >= 0.8) return Colors.blue;
    if (progress >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$correctCount / $totalCount',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 円形進捗インジケータ
class CircularProgressIndicatorWidget extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final String label;
  final String value;
  final Color backgroundColor;
  final Color progressColor;

  const CircularProgressIndicatorWidget({
    required this.progress,
    required this.label,
    required this.value,
    this.backgroundColor = Colors.grey,
    this.progressColor = Colors.blue,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 6,
                backgroundColor: backgroundColor.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
              Center(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

/// 週間学習目標カード
class WeeklyGoalCard extends StatelessWidget {
  final int targetMinutes;
  final int completedMinutes;
  final int daysActive;
  final int daysTarget;

  const WeeklyGoalCard({
    required this.targetMinutes,
    required this.completedMinutes,
    required this.daysActive,
    required this.daysTarget,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentComplete = (completedMinutes / targetMinutes).clamp(0.0, 1.0);
    final isGoalMet = completedMinutes >= targetMinutes;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '今週の学習時間',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isGoalMet ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isGoalMet ? '✅ 達成' : '進行中',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isGoalMet ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentComplete,
                minHeight: 16,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isGoalMet ? Colors.green : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedMinutes / $targetMinutes',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      '分',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$daysActive / $daysTarget',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      '日間学習',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// スポットライト（ハイライト）カード
class ProgressSpotlight extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ProgressSpotlight({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.7),
            color.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// ストリークインジケータ
class StreakWidget extends StatelessWidget {
  final int streakDays;
  final DateTime lastActiveDate;

  const StreakWidget({
    required this.streakDays,
    required this.lastActiveDate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActiveToday = DateTime.now().day == lastActiveDate.day &&
        DateTime.now().month == lastActiveDate.month &&
        DateTime.now().year == lastActiveDate.year;

    // 共通テーマ（漢字検定）の配色で、ライト/ダークとも配色はテーマから取る。
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary,
                  Color.lerp(scheme.primary, Colors.black, 0.25)!,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '🔥',
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '連続学習中',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer.withOpacity(0.75),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$streakDays日間',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActiveToday ? '今日も学習済み ✓' : '今日はまだ学習していません',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActiveToday
                        ? AppColors.success
                        : scheme.onPrimaryContainer.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
