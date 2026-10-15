import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_recommendation.dart';
import '../providers/learning_plan_provider.dart';
import 'package:kanken/widgets/ukalab_emoji.dart';
import 'package:kanken/widgets/text_fit.dart';

class LearningPlanScreen extends ConsumerWidget {
  const LearningPlanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(learningPlanProvider);
    ref.watch(activeLearningRecommendationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('🎯 学習推奨プラン'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: planAsync.when(
        data: (plan) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // プランサマリー
              _buildPlanSummary(plan),
              const SizedBox(height: 20),

              // 推奨リスト
              _buildRecommendationsList(plan),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  /// プランサマリーカード
  Widget _buildPlanSummary(LearningPlan plan) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.cyan.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅 学習プラン概要',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // プランの詳細情報
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    icon: '📚',
                    label: '推奨項目',
                    value: '${plan.recommendations.length}',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryTile(
                    icon: '📅',
                    label: '推定期間',
                    value: '${plan.totalEstimatedDays}日',
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildSummaryTile(
                    icon: '✅',
                    label: '完了',
                    value: '${plan.completedCount}/${plan.recommendations.length}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 完了率プログレスバー
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: plan.completionPercentage,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.green.shade400,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              '完了率: ${(plan.completionPercentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 16),

            // 推奨日次出題数
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '📊 推奨日次出題数:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CapWidth(
                    maxFraction: 0.35,
                    child: Text(
                      '${plan.totalDailyQuestions} 問/日',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// サマリータイル
  Widget _buildSummaryTile({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        UkalabEmoji(icon, size: 24),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// 推奨リスト
  Widget _buildRecommendationsList(LearningPlan plan) {
    if (plan.recommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'すべての分野が良好です！',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 推奨タスク (${plan.recommendations.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plan.recommendations.length,
          itemBuilder: (context, index) {
            final rec = plan.recommendations[index];
            return _buildRecommendationCard(context, rec);
          },
        ),
      ],
    );
  }

  /// 推奨カード
  Widget _buildRecommendationCard(
    BuildContext context,
    LearningRecommendation rec,
  ) {
    final priorityColor = _getPriorityColor(rec.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              priorityColor.withOpacity(0.1),
              priorityColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: priorityColor.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                // 優先度バッジ
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rec.getPriorityLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 難易度
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rec.getDifficultyLabel(),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                    ],
                  ),
                ),

                // 完了チェック
                if (rec.isCompleted)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ターゲット分野
            Text(
              rec.targetCategoryName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 推奨理由
            Text(
              rec.reason,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),

            // 進捗バー（進捗中の場合）
            if (rec.progressAccuracy != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: rec.progressAccuracy,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        rec.canMarkAsCompleted
                            ? Colors.green.shade400
                            : Colors.orange.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '進捗: ${(rec.progressAccuracy! * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),

            // 詳細情報
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 ${rec.recommendedDailyQuestions} 問/日',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📅 ${rec.estimatedDaysToImprove} 日で改善',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '進捗: ${rec.getProgressPercentage()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '期限: ${rec.getUrgencyDays()} 日以内',
                      style: TextStyle(
                        fontSize: 11,
                        color: rec.getUrgencyDays() <= 1
                            ? Colors.red
                            : Colors.grey.shade600,
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

  /// 優先度から色を取得
  Color _getPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.critical:
        return Colors.red;
      case RecommendationPriority.high:
        return Colors.orange;
      case RecommendationPriority.medium:
        return Colors.amber;
      case RecommendationPriority.low:
        return Colors.green;
    }
  }
}
