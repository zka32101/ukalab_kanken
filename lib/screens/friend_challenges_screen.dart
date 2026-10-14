import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_challenge.dart';
import '../providers/friend_challenge_provider.dart';
import 'package:kanken/widgets/text_fit.dart';

class FriendChallengesScreen extends ConsumerWidget {
  const FriendChallengesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChallengesAsync = ref.watch(activeChallengesProvider);
    final sentChallengesAsync = ref.watch(sentChallengesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const FitTitle('フレンドチャレンジ'),
          centerTitle: true,
          elevation: 0,
          bottom: fitTabBar(
            context,
            tabs: const [
              FitTabSpec('受け取ったチャレンジ'),
              FitTabSpec('送信したチャレンジ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 受け取ったチャレンジ
            activeChallengesAsync.when(
              data: (challenges) => _buildReceivedChallenges(challenges, context, ref),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('エラー: $err')),
            ),
            // 送信したチャレンジ
            sentChallengesAsync.when(
              data: (challenges) => _buildSentChallenges(challenges, context, ref),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('エラー: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedChallenges(
    List<FriendChallenge> challenges,
    BuildContext context,
    WidgetRef ref,
  ) {
    if (challenges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🎯',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                'チャレンジはまだありません',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _buildChallengeCard(challenge, context, ref, isReceived: true);
      },
    );
  }

  Widget _buildSentChallenges(
    List<FriendChallenge> challenges,
    BuildContext context,
    WidgetRef ref,
  ) {
    if (challenges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '📤',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                'チャレンジを送信していません',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _buildChallengeCard(challenge, context, ref, isReceived: false);
      },
    );
  }

  Widget _buildChallengeCard(
    FriendChallenge challenge,
    BuildContext context,
    WidgetRef ref, {
    required bool isReceived,
  }) {
    final statusColor = _getStatusColor(challenge.status);
    final statusLabel = _getStatusLabel(challenge.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        isReceived
                            ? '${challenge.challengerName}からのチャレンジ'
                            : '${challenge.changetesName}へのチャレンジ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CapWidth(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // スコア表示（完了した場合）
            if (challenge.status == ChallengeStatus.completed &&
                challenge.challengerScore != null &&
                challenge.challengeeScore != null)
              _buildCompletedScore(challenge, isReceived)
            else
              _buildTargetInfo(challenge),

            const SizedBox(height: 12),

            // 期限表示
            Text(
              '期限: ${_formatDate(challenge.dueAt)}',
              style: TextStyle(
                color: challenge.isExpired ? Colors.red : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),

            // アクション
            if (isReceived && challenge.status == ChallengeStatus.pending)
              _buildActionButtons(challenge, ref, context),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetInfo(FriendChallenge challenge) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 8,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '目標スコア',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            Text(
              '${challenge.targetScore}点',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        if (challenge.status == ChallengeStatus.accepted)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '進行中',
                style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
              ),
              const Text(
                '⏱️ 実施中',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCompletedScore(FriendChallenge challenge, bool isReceived) {
    final winner = challenge.getWinner();
    final isTie = challenge.challengerScore == challenge.challengeeScore;

    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            isTie ? '同点！' : '${winner == challenge.challengerUserId ? challenge.challengerName : challenge.changetesName}が勝利！',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildScoreDisplay(
                  challenge.challengerName,
                  challenge.challengerScore ?? 0,
                ),
              ),
              const Text('vs', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: _buildScoreDisplay(
                  challenge.changetesName,
                  challenge.challengeeScore ?? 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(String name, int score) {
    return Column(
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '$score点',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(FriendChallenge challenge, WidgetRef ref, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await declineChallenge(challenge.challengeId);
                if (context.mounted) {
                  ref.invalidate(activeChallengesProvider);
                }
              },
              child: const Text('拒否'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                await acceptChallenge(challenge.challengeId);
                if (context.mounted) {
                  ref.invalidate(activeChallengesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('チャレンジを受け入れました！')),
                  );
                }
              },
              child: const Text('受け入れる'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.pending:
        return Colors.orange;
      case ChallengeStatus.accepted:
        return Colors.blue;
      case ChallengeStatus.completed:
        return Colors.green;
      case ChallengeStatus.declined:
        return Colors.grey;
    }
  }

  String _getStatusLabel(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.pending:
        return '待機中';
      case ChallengeStatus.accepted:
        return '受け入れ済み';
      case ChallengeStatus.completed:
        return '完了';
      case ChallengeStatus.declined:
        return '拒否';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
