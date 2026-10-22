import 'package:flutter/material.dart';
import 'package:ukalab_core/ui.dart';
import '../router/app_router.dart';

/// 「記録」タブ。進捗・分析・計画・バッジなど、記録系の画面への入口を並べる
/// （各画面は Navigator.push で開く）。バッジは記録タブに置く（オーナー決定）。
class RecordTabScreen extends StatelessWidget {
  const RecordTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('記録')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HomeMenuTile(
            icon: Icons.show_chart,
            title: '進捗',
            subtitle: '級ごとの学習の進み具合を見ます。',
            onTap: () => context.goProgress(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.insights,
            title: '学習分析',
            onTap: () => context.goAnalytics(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.analytics_outlined,
            title: '苦手分析',
            onTap: () => context.goWeakAreas(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.event_note,
            title: '学習計画',
            onTap: () => context.goLearningPlan(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.flag_outlined,
            title: '学習目標',
            onTap: () => context.goLearningGoals(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.history,
            title: '模擬試験の履歴',
            onTap: () => context.goExamHistory(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.card_giftcard,
            title: 'バッジ',
            onTap: () => context.goCollectionBadge(),
          ),
          const SizedBox(height: 16),
          Text('ソーシャル', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.people,
            title: 'フレンド',
            onTap: () => context.goFriends(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.sports_kabaddi,
            title: 'チャレンジ',
            onTap: () => context.goFriendChallenges(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.leaderboard,
            title: 'ランキング',
            onTap: () => context.goGlobalRanking(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.emoji_events,
            title: 'スコアボード',
            onTap: () => context.goLeaderboard(),
          ),
        ],
      ),
    );
  }
}
