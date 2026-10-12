import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard.dart';
import '../providers/leaderboard_provider.dart';
import 'package:kanken/widgets/ukalab_emoji.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardPeriod _selectedPeriod = LeaderboardPeriod.allTime;

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(_getLeaderboardProvider(_selectedPeriod));

    return Scaffold(
      appBar: AppBar(
        title: const Text('リーダーボード'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 期間選択タブ
          _buildPeriodTabs(),
          Expanded(
            child: leaderboardAsync.when(
              data: (leaderboard) => _buildLeaderboard(leaderboard, context),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('エラーが発生しました: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: LeaderboardPeriod.values.map((period) {
            final isSelected = _selectedPeriod == period;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(_getPeriodLabel(period)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedPeriod = period);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLeaderboard(LeaderboardStats leaderboard, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 現在のユーザーの順位
        if (leaderboard.currentUserEntry != null)
          _buildCurrentUserCard(leaderboard.currentUserEntry!, context),

        const SizedBox(height: 24),

        // 上位ランキング
        Text(
          'ランキング',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ...leaderboard.topEntries.asMap().entries.map((entry) {
          final leaderboardEntry = entry.value;
          final medal = _getMedalEmoji(leaderboardEntry.rank);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: UkalabEmoji(medal, size: 24),
              title: Text(
                leaderboardEntry.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '正答率: ${(leaderboardEntry.averageAccuracy * 100).toStringAsFixed(1)}% • '
                '試験: ${leaderboardEntry.examsCompleted}回 • '
                '連続: ${leaderboardEntry.streak}日',
              ),
              trailing: Text(
                '${leaderboardEntry.totalScore}点',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ),
          );
        }).toList(),

        if (leaderboard.topEntries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'ランキングデータがありません',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentUserCard(LeaderboardEntry userEntry, BuildContext context) {
    final medal = _getMedalEmoji(userEntry.rank);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'あなたの順位',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$medal 第${userEntry.rank}位',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEntry.userName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                '${userEntry.totalScore}点',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('正答率', '${(userEntry.averageAccuracy * 100).toStringAsFixed(1)}%', Colors.white70),
              _buildStatItem('試験数', '${userEntry.examsCompleted}回', Colors.white70),
              _buildStatItem('連続', '${userEntry.streak}日', Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getPeriodLabel(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.daily:
        return '日次';
      case LeaderboardPeriod.weekly:
        return '週次';
      case LeaderboardPeriod.monthly:
        return '月次';
      case LeaderboardPeriod.allTime:
        return '全期間';
    }
  }

  String _getMedalEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '${rank > 9 ? '🔹' : '${rank.toString()} '}';
    }
  }

  FutureProvider<LeaderboardStats> _getLeaderboardProvider(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.daily:
        return dailyLeaderboardProvider;
      case LeaderboardPeriod.weekly:
        return weeklyLeaderboardProvider;
      case LeaderboardPeriod.monthly:
        return monthlyLeaderboardProvider;
      case LeaderboardPeriod.allTime:
        return allTimeLeaderboardProvider;
    }
  }
}
