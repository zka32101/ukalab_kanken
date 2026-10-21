import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ukalab_core/learning.dart';

/// 級クリア（演習での正答率達成）を祝う証書風ダイアログ。
/// confetti.json（Lottie）とバッジ獲得SEを使う。
Future<void> showLevelClearCelebration(
  BuildContext context, {
  required String levelName,
  required AnswerFeedback feedback,
}) async {
  // バッジ獲得SE＋触覚
  await feedback.badgeUnlocked();

  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/confetti.json',
                    repeat: false,
                    fit: BoxFit.contain,
                  ),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber[100],
                      border: Border.all(color: Colors.amber[700]!, width: 3),
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      size: 60,
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '🎉 級クリア！',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange[700],
              ),
            ),
            const SizedBox(height: 12),
            // 証書風の文面
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[300]!, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    '認 定 証',
                    style: TextStyle(fontSize: 14, letterSpacing: 4, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    levelName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'あなたはこの級の問題で\n高い正答率を達成しました。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  '次の級に挑戦する',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
