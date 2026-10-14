import 'package:flutter/material.dart';
import '../models/achievement.dart';
import 'package:kanken/widgets/ukalab_emoji.dart';

class AchievementUnlockDialog extends StatefulWidget {
  final List<Achievement> achievements;
  final VoidCallback onComplete;

  const AchievementUnlockDialog({
    required this.achievements,
    required this.onComplete,
    Key? key,
  }) : super(key: key);

  @override
  State<AchievementUnlockDialog> createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextAchievement() {
    if (_currentIndex < widget.achievements.length - 1) {
      _controller.reset();
      setState(() => _currentIndex++);
      _controller.forward();
    } else {
      widget.onComplete();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievements[_currentIndex];
    final totalCount = widget.achievements.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade400,
                Colors.blue.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ページインジケータ
              if (totalCount > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: Text(
                      '${_currentIndex + 1} / $totalCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // アイコン
              UkalabEmoji(achievement.icon, size: 80),
              const SizedBox(height: 16),

              // 「新しいバッジを獲得」
              const Text(
                '🎉 新しいバッジを獲得！',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // バッジ名
              Text(
                achievement.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 説明
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // ポイント
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+ ${achievement.points} ポイント',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextAchievement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    totalCount > 1 && _currentIndex < totalCount - 1
                        ? '次へ'
                        : '完了',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

/// バッジ表示ウィジェット（コンパクト版）
class AchievementBadgeWidget extends StatelessWidget {
  final Achievement achievement;
  final bool showPoints;

  const AchievementBadgeWidget({
    required this.achievement,
    this.showPoints = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: achievement.isUnlocked
                ? Colors.purple.shade100
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: achievement.isUnlocked
                  ? Colors.purple.shade400
                  : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Center(
            child: UkalabEmoji(achievement.icon, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          achievement.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: achievement.isUnlocked ? Colors.black : Colors.grey,
          ),
        ),
        if (showPoints && achievement.isUnlocked)
          Text(
            '+${achievement.points}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.purple.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
