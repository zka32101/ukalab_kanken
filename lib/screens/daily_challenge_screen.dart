import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_challenge.dart';
import '../models/gamification_stats.dart';
import '../providers/daily_challenge_provider.dart';
import '../providers/gamification_provider.dart';
import 'package:kanken/widgets/ukalab_emoji.dart';
import 'package:kanken/widgets/text_fit.dart';

/// デイリーチャレンジ画面
class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(dailyChallengeProvider);
    final statsAsync = ref.watch(gamificationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('デイリーチャレンジ'),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
      ),
      body: challengeAsync.when(
        data: (challenge) => statsAsync.when(
          data: (stats) => _buildChallengeBody(
            context,
            challenge,
            stats,
            ref,
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, stack) => Center(
            child: Text('エラー: $err'),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Text('エラー: $err'),
        ),
      ),
    );
  }

  Widget _buildChallengeBody(
    BuildContext context,
    DailyChallenge challenge,
    GamificationStats stats,
    WidgetRef ref,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ヘッダー＆本日のチャレンジタイトル
          _buildHeader(context, challenge),
          const SizedBox(height: 24),

          // 2. ユーザー統計カード（3列）
          _buildStatsRow(stats),
          const SizedBox(height: 24),

          // 3. チャレンジ詳細カード
          _buildChallengeCard(context, challenge),
          const SizedBox(height: 24),

          // 4. チャレンジ開始ボタン
          _buildStartButton(context, challenge, stats),
          const SizedBox(height: 24),

          // 5. ボーナス情報
          _buildBonusInfo(stats),
          const SizedBox(height: 16),

          // 6. 説明テキスト
          _buildDescription(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DailyChallenge challenge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '本日のチャレンジ',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                challenge.date,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 24),
            if (challenge.isExpired)
              Chip(
                label: const Text('期限切れ'),
                backgroundColor: Colors.red.withAlpha(50),
                labelStyle: const TextStyle(color: Colors.red),
              )
            else
              Chip(
                label: const Text('有効'),
                backgroundColor: Colors.green.withAlpha(50),
                labelStyle: const TextStyle(color: Colors.green),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(GamificationStats stats) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'レベル',
            value: '${stats.level}',
            icon: '⭐',
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'コイン',
            value: '${stats.coins}',
            icon: '💰',
            color: Colors.yellow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'ストリーク',
            value: '${stats.streak}日',
            icon: '🔥',
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    DailyChallenge challenge,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'チャレンジ詳細',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _ChallengeInfoRow(
              icon: Icons.quiz,
              label: '問題数',
              value: '${challenge.questionCount}問',
            ),
            const SizedBox(height: 12),
            _ChallengeInfoRow(
              icon: Icons.speed,
              label: '難度',
              value: _getDifficultyLabel(challenge.difficulty),
            ),
            const SizedBox(height: 12),
            _ChallengeInfoRow(
              icon: Icons.access_time,
              label: 'リセット時刻',
              value: '${challenge.resetTime.hour}:${challenge.resetTime.minute.toString().padLeft(2, '0')}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(
    BuildContext context,
    DailyChallenge challenge,
    GamificationStats stats,
  ) {
    final isExpired = challenge.isExpired;

    return ElevatedButton(
      onPressed: isExpired
          ? null
          : () {
            // チャレンジ詳細画面へ遷移
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('チャレンジ詳細画面へ遷移')),
            );
          },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blueAccent,
        disabledBackgroundColor: Colors.grey,
      ),
      child: Text(
        isExpired ? 'チャレンジ期限切れ' : 'チャレンジを開始',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBonusInfo(GamificationStats stats) {
    return Card(
      color: Colors.amber.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                const Text('🎉 本日のボーナス', style: TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${stats.getRank()}'),
                  ),
                  backgroundColor: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BonusItem(icon: '✨', text: '完了時: +100 コイン'),
            const SizedBox(height: 8),
            _BonusItem(icon: '⭐', text: '全問正解: +50 EXP'),
            const SizedBox(height: 8),
            _BonusItem(
              icon: '🔥',
              text: 'ストリーク: 連続 ${stats.streak} 日！',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '毎日チャレンジに挑戦して、経験値とコインを獲得しよう！\nストリーク継続でボーナスがもらえます。',
        style: TextStyle(fontSize: 12, color: Colors.blue),
      ),
    );
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return '簡単 🟢';
      case 'medium':
        return '通常 🟡';
      case 'hard':
        return '難しい 🔴';
      default:
        return '通常 🟡';
    }
  }
}

/// 統計タイル
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            UkalabEmoji(icon, size: 28),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
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
        ),
      ),
    );
  }
}

/// チャレンジ情報行
class _ChallengeInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ChallengeInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 8),
        FitWidth(
          maxFraction: 0.45,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// ボーナスアイテム
class _BonusItem extends StatelessWidget {
  final String icon;
  final String text;

  const _BonusItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UkalabEmoji(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
