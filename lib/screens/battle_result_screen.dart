import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/multiplayer.dart';
import 'package:kanken/widgets/text_fit.dart';

class BattleResultScreen extends StatelessWidget {
  final BattleResult result;

  const BattleResultScreen({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ranking = result.getRanking();

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('対戦結果'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 優勝者表示
              _buildWinnerCard(context, ranking.first),
              const SizedBox(height: 32),

              // ランキング
              _buildRankingList(context, ranking),
              const SizedBox(height: 32),

              // 対戦統計
              _buildBattleStats(context),
              const SizedBox(height: 32),

              // ボタン
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerCard(BuildContext context, BattleParticipant winner) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber.shade400, Colors.amber.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            '優勝！',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            winner.displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${winner.currentScore}点',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(
    BuildContext context,
    List<BattleParticipant> ranking,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最終成績',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...ranking.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final participant = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getRankColor(rank).withOpacity(0.1),
                border: Border.all(
                  color: _getRankColor(rank),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getRankColor(rank),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$rank',
                          style:
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          participant.displayName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '正答: ${participant.correctAnswers}問',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FitWidth(
                    maxFraction: 0.3,
                    child: Text(
                      '${participant.currentScore}点',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getRankColor(rank),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBattleStats(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '対戦情報',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              '参加人数',
              '${result.finalParticipants.length}人',
            ),
            const Divider(),
            _buildStatRow(
              '対戦時間',
              _formatDuration(result.totalDurationSeconds),
            ),
            const Divider(),
            _buildStatRow(
              '完了時刻',
              _formatDateTime(result.completedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 2,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('もう一度対戦'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            context.go('/battle-rooms');
          },
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.home),
          label: const Text('ホームに戻る'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            context.go('/');
          },
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade500;
      case 3:
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes分${secs}秒';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
