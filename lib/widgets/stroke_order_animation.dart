import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import '../models/stroke_order.dart';

/// 漢字の書き順を1画ずつアニメーション表示するウィジェット
class StrokeOrderAnimationWidget extends StatefulWidget {
  final StrokeOrderData data;
  final double size;
  final Duration strokeDuration;

  const StrokeOrderAnimationWidget({
    required this.data,
    this.size = 240,
    this.strokeDuration = const Duration(milliseconds: 500),
    Key? key,
  }) : super(key: key);

  @override
  State<StrokeOrderAnimationWidget> createState() =>
      _StrokeOrderAnimationWidgetState();
}

class _StrokeOrderAnimationWidgetState
    extends State<StrokeOrderAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Path> _strokePaths;

  @override
  void initState() {
    super.initState();
    _parsePaths();
    _controller = AnimationController(
      duration: widget.strokeDuration * widget.data.strokeCount,
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant StrokeOrderAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.kanji != widget.data.kanji) {
      _parsePaths();
      _controller.duration = widget.strokeDuration * widget.data.strokeCount;
      _controller.reset();
      _controller.forward();
    }
  }

  void _parsePaths() {
    _strokePaths = widget.data.strokePaths
        .map((svg) => parseSvgPathData(svg))
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void replay() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _StrokeOrderPainter(
                  strokePaths: _strokePaths,
                  progress: _controller.value,
                  gridSize: widget.data.viewBox,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '全${widget.data.strokeCount}画',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: replay,
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('もう一度'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StrokeOrderPainter extends CustomPainter {
  final List<Path> strokePaths;
  final double progress; // 0.0 - 1.0（全体の進捗）
  final double gridSize;

  _StrokeOrderPainter({
    required this.strokePaths,
    required this.progress,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / gridSize;
    canvas.save();
    canvas.scale(scale, scale);

    _drawGuideLines(canvas);

    if (strokePaths.isEmpty) {
      canvas.restore();
      return;
    }

    final totalStrokes = strokePaths.length;
    final rawIndex = progress * totalStrokes;
    final currentStrokeIndex = rawIndex.floor().clamp(0, totalStrokes - 1);
    final currentStrokeProgress = (rawIndex - currentStrokeIndex).clamp(0.0, 1.0);

    final completedPaint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final activePaint = Paint()
      ..color = const Color(0xFF3B6CF2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 完了済みのストロークを描画
    for (int i = 0; i < currentStrokeIndex; i++) {
      canvas.drawPath(strokePaths[i], completedPaint);
      _drawStrokeNumber(canvas, strokePaths[i], i + 1, isActive: false);
    }

    // 現在描画中のストロークをアニメーション表示
    final activePath = strokePaths[currentStrokeIndex];
    final metrics = activePath.computeMetrics().toList();
    final partialPath = Path();
    for (final metric in metrics) {
      final extractLength = metric.length * currentStrokeProgress;
      partialPath.addPath(metric.extractPath(0, extractLength), Offset.zero);
    }
    canvas.drawPath(partialPath, activePaint);
    if (currentStrokeProgress > 0.05) {
      _drawStrokeNumber(canvas, activePath, currentStrokeIndex + 1, isActive: true);
    }

    canvas.restore();
  }

  void _drawGuideLines(Canvas canvas) {
    final guidePaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, gridSize / 2), Offset(gridSize, gridSize / 2), guidePaint);
    canvas.drawLine(Offset(gridSize / 2, 0), Offset(gridSize / 2, gridSize), guidePaint);
  }

  void _drawStrokeNumber(Canvas canvas, Path path, int number, {required bool isActive}) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final startTangent = metrics.first.getTangentForOffset(0);
    if (startTangent == null) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isActive ? const Color(0xFF3B6CF2) : Colors.grey.shade500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelOffset = startTangent.position + const Offset(-4, -10);
    textPainter.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant _StrokeOrderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.strokePaths != strokePaths;
  }
}
