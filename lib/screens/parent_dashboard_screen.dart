import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_label.dart';
import '../models/parent_dashboard.dart';
import '../providers/parent_dashboard_provider.dart';
import 'package:kanken/widgets/ukalab_emoji.dart';
import 'package:kanken/widgets/text_fit.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(linkedChildrenProvider);
    final dashboardState = ref.watch(
      parentDashboardNotifierProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('👨‍👩‍👧 保護者ダッシュボード'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: childrenAsync.when(
        data: (children) {
          if (children.isEmpty) {
            return _buildNoChildrenView();
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 子ども選択
                _buildChildSelector(children),
                const SizedBox(height: 16),

                // 統計情報
                _buildStatisticsSection(children),
                const SizedBox(height: 16),

                // 学習グラフ
                if (dashboardState.selectedChildId != null)
                  _buildLearningGraph(
                    children.firstWhere(
                      (c) => c.childId == dashboardState.selectedChildId,
                    ),
                  ),
                const SizedBox(height: 16),

                // 弱点分野
                if (dashboardState.selectedChildId != null)
                  _buildWeakAreasSection(
                    children.firstWhere(
                      (c) => c.childId == dashboardState.selectedChildId,
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddChildDialog(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 子どもがいない場合の表示
  Widget _buildNoChildrenView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'リンクされた子どもがいません',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'お子さんのメールアドレスを追加して、\n学習の進捗を監視できます。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('子どもを追加'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showAddChildDialog(),
            ),
          ],
        ),
      ),
    );
  }

  /// 子ども選択セクション
  Widget _buildChildSelector(List<ChildLearningStats> children) {
    final state = ref.watch(
      parentDashboardNotifierProvider,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'お子さん',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: children.map((child) {
                final isSelected = state.selectedChildId == child.childId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(child.childName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref
                            .read(parentDashboardNotifierProvider.notifier)
                            .selectChild(child.childId);
                      }
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Colors.blue.shade300,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 統計情報セクション
  Widget _buildStatisticsSection(List<ChildLearningStats> children) {
    final state = ref.watch(
      parentDashboardNotifierProvider,
    );
    final selectedChild = state.selectedChildId != null
        ? children.firstWhere(
            (c) => c.childId == state.selectedChildId,
            orElse: () => children[0],
          )
        : children[0];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${selectedChild.childName}の学習統計',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: gridColumns(context, 2),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: gridColumnsAspect(context, 2, 1.0),
            children: [
              _buildStatCard(
                icon: '✅',
                label: '正答率',
                value: selectedChild.getAccuracyPercentage(),
                color: Colors.green,
              ),
              _buildStatCard(
                icon: '🔥',
                label: 'ストリーク',
                value: '${selectedChild.streakDays}日',
                color: Colors.orange,
              ),
              _buildStatCard(
                icon: '🎖️',
                label: 'バッジ',
                value: '${selectedChild.badgesAcquired}/${selectedChild.totalBadges}',
                color: Colors.amber,
              ),
              _buildStatCard(
                icon: '⏱️',
                label: '学習時間',
                value: '${selectedChild.totalLearningMinutes}分',
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selectedChild.isActiveLearner()
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selectedChild.isActiveLearner()
                    ? Colors.green.shade300
                    : Colors.orange.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selectedChild.isActiveLearner()
                      ? Icons.check_circle
                      : Icons.warning,
                  color: selectedChild.isActiveLearner()
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedChild.isActiveLearner()
                            ? '継続中 🎉'
                            : '学習が必要です',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: selectedChild.isActiveLearner()
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      Text(
                        selectedChild.isActiveLearner()
                            ? 'お子さんは${selectedChild.streakDays}日間の学習を継続しています'
                            : '最後の学習から${selectedChild.getDaysSinceLastLearning()}日経過しています',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 統計カード
  Widget _buildStatCard({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UkalabEmoji(icon, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
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
      ),
    );
  }

  /// 学習グラフセクション
  Widget _buildLearningGraph(ChildLearningStats child) {
    final graphAsync = ref.watch(childLearningGraphProvider(child.childId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 学習グラフ（過去30日間）',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          graphAsync.when(
            data: (data) {
              if (data.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'データがありません',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              // 簡易グラフ（正答率の推移）
              final maxAccuracy =
                  data.fold(0.0, (max, p) => p.accuracyRate > max ? p.accuracyRate : max);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 100,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: data
                            .asMap()
                            .entries
                            .map((entry) {
                              final accuracy =
                                  entry.value.accuracyRate / (maxAccuracy > 0 ? maxAccuracy : 1);
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Container(
                                    height: 100 * accuracy,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '正答率の推移（7日ごと）',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('エラー: $error'),
          ),
        ],
      ),
    );
  }

  /// 弱点分野セクション
  Widget _buildWeakAreasSection(ChildLearningStats child) {
    final weakAreasAsync =
        ref.watch(childWeakAreasProvider(child.childId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️ 改善が必要な分野',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          weakAreasAsync.when(
            data: (weakAreas) {
              final needsImprovement =
                  weakAreas.where((a) => a.needsImprovement()).toList();

              if (needsImprovement.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'すべて良好です 🎉',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'お子さんのすべての分野が良好な状態です',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: needsImprovement.length,
                itemBuilder: (context, index) {
                  final area = needsImprovement[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                categoryLabel(area.categoryName),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CapWidth(
                              maxFraction: 0.3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  area.getLevelLabel(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: area.accuracyRate,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade300,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                              Colors.orange.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '正答率: ${(area.accuracyRate * 100).toStringAsFixed(1)}% (${area.correctAnswers}/${area.totalAttempts})',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('エラー: $error'),
          ),
        ],
      ),
    );
  }

  /// 子ども追加ダイアログ
  void _showAddChildDialog() {
    _emailController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('お子さんを追加'),
        content: TextField(
          controller: _emailController,
          decoration: InputDecoration(
            label: const FitTitle('お子さんのメールアドレス'),
            // 文字が大きい・画面が狭いときは、「…」で省略せず、収まるまで縮めて全体を見せる。
            hint: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'example@email.com',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_emailController.text.isNotEmpty) {
                ref
                    .read(parentDashboardNotifierProvider.notifier)
                    .linkChild(childEmail: _emailController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }
}
