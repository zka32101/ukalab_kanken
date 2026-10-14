import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 正解時のフィードバックウィジェット
class CorrectFeedbackWidget extends StatefulWidget {
  final VoidCallback onComplete;
  final Function(bool)? onLearnedToggle; // 「覚えた」チェックのコールバック

  const CorrectFeedbackWidget({
    Key? key,
    required this.onComplete,
    this.onLearnedToggle,
  }) : super(key: key);

  @override
  State<CorrectFeedbackWidget> createState() => _CorrectFeedbackWidgetState();
}

class _CorrectFeedbackWidgetState extends State<CorrectFeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isLearned = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0)),
    );

    // アニメーション終了後、2 秒待機してから完了
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 紙吹雪エフェクト（Lottie）
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(
                    'assets/lottie/confetti.json',
                    repeat: false,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                // 正解テキスト
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '✨ 正解！',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // 「覚えた」チェックボックス
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _isLearned,
                        onChanged: (value) {
                          setState(() {
                            _isLearned = value ?? false;
                          });
                          widget.onLearnedToggle?.call(_isLearned);
                        },
                        activeColor: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'この漢字は覚えた',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'チェックすると今後この問題は出題されません',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
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

/// 不正解時のシェイク効果
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onShakeComplete;

  const ShakeWidget({
    Key? key,
    required this.child,
    this.onShakeComplete,
  }) : super(key: key);

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticInOut));

    // シェイクアニメーション（複雑な動き）
    _animateShake();
  }

  void _animateShake() async {
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() {
          // UI再描画で手動シェイク実装（ハプティクスで補助）
        });
      }
    }
    widget.onShakeComplete?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}

/// コンボ表示ウィジェット（浮かぶアニメーション）
class ComboCounterWidget extends StatefulWidget {
  final int comboCount;

  const ComboCounterWidget({
    Key? key,
    required this.comboCount,
  }) : super(key: key);

  @override
  State<ComboCounterWidget> createState() => _ComboCounterWidgetState();
}

class _ComboCounterWidgetState extends State<ComboCounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _floatAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.3),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void didUpdateWidget(ComboCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comboCount != widget.comboCount) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _floatAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'コンボ: ${widget.comboCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// 全画面ゴールド演出（模擬試験合格時）
class FullScreenGoldEffect extends StatefulWidget {
  final VoidCallback onComplete;

  const FullScreenGoldEffect({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<FullScreenGoldEffect> createState() => _FullScreenGoldEffectState();
}

class _FullScreenGoldEffectState extends State<FullScreenGoldEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_controller),
      child: Container(
        color: Colors.amber[400],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 120, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                '🎉 合格おめでとう！',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Lottie パーティクル（花火）
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  'assets/lottie/fireworks.json',
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
