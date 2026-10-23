import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../models/stroke_order.dart';

/// 漢字の全ての画を灰色で描き、[highlightIndex]（0始まり）の画だけを赤で描く。
/// 漢検の「筆順」の問題（赤い画は何画目？）の表示に使う。画の番号は出さない。
class StrokeHighlightView extends StatelessWidget {
  final StrokeOrderData data;
  final int highlightIndex;
  final double size;

  const StrokeHighlightView({
    required this.data,
    required this.highlightIndex,
    this.size = 200,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final paths = [for (final svg in data.strokePaths) parseSvgPathData(svg)];
    return Semantics(
      label: '「${data.kanji}」の${highlightIndex + 1}画目を赤で示した図',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: CustomPaint(
          painter: _HighlightPainter(
            paths: paths,
            highlightIndex: highlightIndex,
            gridSize: data.viewBox,
          ),
        ),
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final List<Path> paths;
  final int highlightIndex;
  final double gridSize;

  _HighlightPainter({
    required this.paths,
    required this.highlightIndex,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / gridSize;
    canvas.save();
    canvas.scale(scale, scale);

    final guide = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, gridSize / 2), Offset(gridSize, gridSize / 2), guide);
    canvas.drawLine(Offset(gridSize / 2, 0), Offset(gridSize / 2, gridSize), guide);

    Paint stroke(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final normal = stroke(const Color(0xFF6B7280));
    final highlight = stroke(const Color(0xFFE11D48));

    // 赤い画を最後（いちばん上）に描く。
    for (var i = 0; i < paths.length; i++) {
      if (i != highlightIndex) canvas.drawPath(paths[i], normal);
    }
    if (highlightIndex >= 0 && highlightIndex < paths.length) {
      canvas.drawPath(paths[highlightIndex], highlight);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter old) =>
      old.highlightIndex != highlightIndex || old.paths != paths;
}
