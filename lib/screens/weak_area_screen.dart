import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_label.dart';
import '../models/weak_area.dart';
import '../providers/weak_area_provider.dart';
import 'package:kanken/widgets/ukalab_emoji.dart';
import 'package:kanken/widgets/text_fit.dart';

class WeakAreaScreen extends ConsumerWidget {
  const WeakAreaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(weakAreaAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('📊 苦手分野分析'),
        centerTitle: true,
        backgroundColor: Colors.red.shade50,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: analysisAsync.when(
        data: (analysis) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 全体統計カード
              _buildOverallStatsCard(analysis),
              const SizedBox(height: 20),

              // 苦手分野の警告
              if (analysis.weakAreas.isNotEmpty)
                _buildWeakWarningCard(analysis),
              const SizedBox(height: 20),

              // 苦手分野リスト
              _buildWeakAreasList(analysis),
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

  /// 全体統計カード
  Widget _buildOverallStatsCard(WeakAreaAnalysis analysis) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.indigo.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 学習統計',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 統計グリッド
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildStatTile(
                    icon: '📚',
                    label: '分野数',
                    value: '${analysis.totalCategories}',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatTile(
                    icon: '⚠️',
                    label: '苦手分野',
                    value: '${analysis.weakCategoryCount}',
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatTile(
                    icon: '⭐',
                    label: '全体正答率',
                    value: '${(analysis.overallAccuracy * 100).toStringAsFixed(1)}%',
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 統計タイル
  Widget _buildStatTile({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        UkalabEmoji(icon, size: 28),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
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
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// 苦手分野警告カード
  Widget _buildWeakWarningCard(WeakAreaAnalysis analysis) {
    final worstArea = analysis.getWorstArea();
    if (worstArea == null) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.red.shade50, Colors.orange.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.red.shade300, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '🎯 最も苦手な分野',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    worstArea.getLevelLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              categoryLabel(worstArea.categoryName),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 正答率バー
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: worstArea.accuracyRate,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.red.shade400,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '正答率: ${worstArea.getAccuracyPercentage()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '出題数: ${worstArea.totalAttempts}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 苦手分野リスト
  Widget _buildWeakAreasList(WeakAreaAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 全分野 (${analysis.totalCategories})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (analysis.allAreas.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'まだ分析データがありません',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: analysis.allAreas.length,
            itemBuilder: (context, index) {
              final area = analysis.allAreas[index];
              return _buildAreaCard(area);
            },
          ),
      ],
    );
  }

  /// 分野カード
  Widget _buildAreaCard(WeakArea area) {
    final isWeak = area.needsImprovement;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isWeak
                ? [Colors.red.shade50, Colors.orange.shade50]
                : [Colors.green.shade50, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryLabel(area.categoryName),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        area.getLevelLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isWeak ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  area.getLevelEmoji(),
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 正答率バー
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: area.accuracyRate,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isWeak ? Colors.red.shade400 : Colors.green.shade400,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 詳細情報
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '正答率: ${area.getAccuracyPercentage()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${area.correctAnswers}/${area.totalAttempts}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),

            if (area.problematicKanjiIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '苦手: ${area.problematicKanjiIds.length} 個',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
