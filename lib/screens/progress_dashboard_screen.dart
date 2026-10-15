import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/gamification_stats.dart';
import '../providers/gamification_provider.dart';
import 'package:kanken/widgets/text_fit.dart';
import 'package:kanken/widgets/ukalab_emoji.dart';

/// 学習進捗ダッシュボード画面
class ProgressDashboardScreen extends ConsumerWidget {
  const ProgressDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(gamificationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('学習進捗'),
        elevation: 0,
        backgroundColor: Colors.purple.shade400,
      ),
      body: statsAsync.when(
        data: (stats) => _buildDashboard(context, stats),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Text('エラー: $err'),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    GamificationStats stats,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. レベル＆経験値セクション
          _buildLevelCard(context, stats),
          const SizedBox(height: 24),

          // 2. 学習統計カード
          _buildStatsCard(context, stats),
          const SizedBox(height: 24),

          // 3. 週別正解率グラフ
          _buildWeeklyAccuracyChart(context, stats),
          const SizedBox(height: 24),

          // 4. 分野別進捗（シミュレーション）
          _buildCategoryProgress(context),
          const SizedBox(height: 24),

          // 5. ランク＆ストリーク
          _buildRankAndStreak(context, stats),
        ],
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    GamificationStats stats,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'レベル',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FitWidth(
                  child: Text(
                    '${stats.level}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '次のレベルまで',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: stats.expProgress,
                          minHeight: 12,
                          backgroundColor: Colors.white30,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.yellow.shade300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${stats.experience} / ${stats.level * 500} EXP',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    GamificationStats stats,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '学習統計',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _StatColumn(
                    label: '総問題数',
                    value: '${stats.totalQuestions}',
                    icon: '📝',
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    label: '正解数',
                    value: '${stats.correctCount}',
                    icon: '✅',
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    label: '正答率',
                    value: '${(stats.accuracyRate * 100).toStringAsFixed(1)}%',
                    icon: '📊',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAccuracyChart(
    BuildContext context,
    GamificationStats stats,
  ) {
    // シミュレーションデータ（実際には Firestore から取得）
    final weeklyData = [75.0, 80.0, 78.0, 85.0, 82.0, 88.0, 90.0];
    final days = ['月', '火', '水', '木', '金', '土', '日'];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '週別正解率',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 10,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withAlpha(50),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withAlpha(50),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= days.length) {
                            return const SizedBox();
                          }
                          return Text(
                            days[index],
                            style: const TextStyle(fontSize: 12),
                            textScaler: chartTextScaler(context),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32 * chartTextScaler(context).scale(1),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 10),
                            textScaler: chartTextScaler(context),
                          );
                        },
                        interval: 10,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withAlpha(100),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: Colors.grey.withAlpha(100),
                        width: 1,
                      ),
                    ),
                  ),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        weeklyData.length,
                        (i) => FlSpot(i.toDouble(), weeklyData[i]),
                      ),
                      isCurved: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue,
                            strokeWidth: 2,
                            strokeColor: Colors.blueAccent,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withAlpha(50),
                      ),
                      color: Colors.blueAccent,
                      barWidth: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgress(BuildContext context) {
    // シミュレーションデータ
    final categories = ['基本漢字', '音読み', '訓読み', '四字熟語', '熟語'];
    final progress = [85.0, 72.0, 68.0, 75.0, 80.0];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '分野別進捗',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= categories.length) {
                            return const SizedBox();
                          }
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              categories[index],
                              style: const TextStyle(fontSize: 10),
                              textScaler: chartTextScaler(context),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32 * chartTextScaler(context).scale(1),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 10),
                            textScaler: chartTextScaler(context),
                          );
                        },
                        interval: 20,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    categories.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: progress[i],
                          color: Colors.teal.shade300,
                          width: 20,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankAndStreak(
    BuildContext context,
    GamificationStats stats,
  ) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('👑 ランク', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Text(
                    stats.getRank(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('🔥 ストリーク', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Text(
                    '${stats.streak}日',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '記録: ${stats.recordStreak}日',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 統計カラム
class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UkalabEmoji(icon, size: 24),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
