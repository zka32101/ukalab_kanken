import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('受験までの残り日数表示は赤字・警告色を使わない（煽らない方針）', () {
    final src =
        File('lib/screens/learning_goals_screen.dart').readAsStringSync();
    final start = src.indexOf('Widget _buildExamCountdown');
    final end = src.indexOf('double? _averageAchievementRate');
    expect(start, isNonNegative);
    expect(end, greaterThan(start));
    final block = src.substring(start, end);
    expect(block.contains('Colors.red'), isFalse);
    expect(block.contains('colorScheme.error'), isFalse);
  });
}
