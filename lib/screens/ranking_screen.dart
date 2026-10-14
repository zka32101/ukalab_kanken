import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanken/models/user_ranking.dart';
import 'package:kanken/providers/ranking_provider.dart';
import 'package:kanken/widgets/text_fit.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  RankingType _selectedType = RankingType.level;
  RankingPeriod _selectedPeriod = RankingPeriod.allTime;

  @override
  Widget build(BuildContext context) {
    final filter = RankingFilter(
      type: _selectedType,
      period: _selectedPeriod,
      limit: 100,
    );

    final rankingAsyncValue = ref.watch(rankingProvider(filter));
    final userRankAsyncValue = ref.watch(userRankProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('ランキング'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ユーザー順位表示
            _buildUserRankCard(userRankAsyncValue),
            const SizedBox(height: 16),

            // フィルタータブ
            _buildFilterTabs(),
            const SizedBox(height: 16),

            // ランキング一覧
            rankingAsyncValue.when(
              data: (rankings) => _buildRankingList(rankings),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'エラーが発生しました: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRankCard(AsyncValue<int?> userRankAsyncValue) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: userRankAsyncValue.when(
        data: (rank) => Column(
          children: [
            const Text(
              'あなたの順位',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (rank != null) ...[
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        rank.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '位',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                    ),
                  ),
                ] else
                  const Text(
                    'ログインしてください',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ],
        ),
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const Text(
          '順位を取得できません',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Column(
      children: [
        // ランキングタイプ選択
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTypeChip(RankingType.level, 'レベル'),
                const SizedBox(width: 8),
                _buildTypeChip(RankingType.experience, '経験値'),
                const SizedBox(width: 8),
                _buildTypeChip(RankingType.accuracy, '正答率'),
                const SizedBox(width: 8),
                _buildTypeChip(RankingType.streak, 'ストリーク'),
                const SizedBox(width: 8),
                _buildTypeChip(RankingType.coins, 'コイン'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 期間選択
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildPeriodChip(RankingPeriod.weekly, '週間'),
                const SizedBox(width: 8),
                _buildPeriodChip(RankingPeriod.monthly, '月間'),
                const SizedBox(width: 8),
                _buildPeriodChip(RankingPeriod.allTime, '全期間'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(RankingType type, String label) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedType = type);
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue.shade300,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildPeriodChip(RankingPeriod period, String label) {
    final isSelected = _selectedPeriod == period;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = period);
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.green.shade300,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildRankingList(List<UserRanking> rankings) {
    if (rankings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('ランキングデータがありません'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rankings.length,
      itemBuilder: (context, index) => _buildRankingCard(rankings[index]),
    );
  }

  Widget _buildRankingCard(UserRanking ranking) {
    final isMedal = ranking.rank <= 3;
    final medalColor = ranking.rank == 1
        ? Colors.amber
        : ranking.rank == 2
            ? Colors.grey
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMedal
            ? medalColor.withOpacity(0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isMedal
            ? Border.all(color: medalColor.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // ランク表示
          SizedBox(
            width: 50,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  ranking.getRankBadge(),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ユーザー情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _buildStat('Lv', ranking.level.toString()),
                    _buildStat('EXP', ranking.experience.toString()),
                    _buildStat('正答率', '${(ranking.accuracyRate * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ],
            ),
          ),

          // ストリーク
          FitWidth(
            maxFraction: 0.25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '🔥 ${ranking.streak}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '連続',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
