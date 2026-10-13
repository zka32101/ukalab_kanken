import 'package:flutter/material.dart';

import '../models/level_progress.dart';
import 'progress_visualization.dart';

/// ホームの「選択中の級」の進捗カード。
///
/// [noQuestions] が true（その級の問題がまだ無い）のときは、「0 / 0」や
/// 「あと20問正解で次の級へ！」を出さず、準備中の案内にする。
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({
    super.key,
    required this.levelLabel,
    required this.progress,
    this.noQuestions = false,
  });

  final String levelLabel;
  final LevelProgress progress;
  final bool noQuestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (noQuestions) ...[
            Text(levelLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.hourglass_empty, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'この級の問題は、準備中です',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ] else ...[
            CategoryProgressBar(
              category: levelLabel,
              progress: progress.accuracyRate,
              correctCount: progress.correctCount,
              totalCount: progress.totalCount,
            ),
            if (progress.isCleared)
              const Text(
                '✅ この級はクリア基準を達成しています！',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
              )
            else
              Text(
                'あと${progress.remainingCorrectToClear}問正解で次の級へ！',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
