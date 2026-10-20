import 'dart:math' show pow;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/theme/app_theme.dart';
import 'package:ukalab_core/ui.dart';

double _contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final l1 = lum(a), l2 = lum(b);
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('ライト/ダークとも共通テーマの漢字検定の配色で構築できる', () {
    final light = AppTheme.light().colorScheme;
    final dark = AppTheme.dark().colorScheme;
    expect(light.primary, UkalabCert.kanjiKentei.light);
    expect(dark.primary, UkalabCert.kanjiKentei.dark);
  });

  test('主要な塗り色と文字色のコントラストは AA（4.5:1）以上', () {
    for (final t in [AppTheme.light(), AppTheme.dark()]) {
      final s = t.colorScheme;
      expect(_contrast(s.primary, s.onPrimary), greaterThanOrEqualTo(4.5));
      expect(_contrast(s.primaryContainer, s.onPrimaryContainer), greaterThanOrEqualTo(4.5));
      expect(_contrast(s.secondary, s.onSecondary), greaterThanOrEqualTo(4.5));
      expect(_contrast(s.surface, s.onSurface), greaterThanOrEqualTo(4.5));
      expect(_contrast(s.error, s.onError), greaterThanOrEqualTo(4.5));
    }
  });

  test('本文・見出しの文字色が背景に対して AA 以上', () {
    for (final t in [AppTheme.light(), AppTheme.dark()]) {
      final bg = t.scaffoldBackgroundColor;
      final body = t.textTheme.bodyMedium?.color ?? t.colorScheme.onSurface;
      expect(_contrast(body, bg), greaterThanOrEqualTo(4.5));
      final title = t.textTheme.titleLarge?.color ?? t.colorScheme.onSurface;
      expect(_contrast(title, bg), greaterThanOrEqualTo(4.5));
    }
  });

  test('画面に直接使う機能色（白文字を載せる塗り）も AA 以上', () {
    expect(_contrast(AppColors.primary, Colors.white), greaterThanOrEqualTo(4.5));
    expect(_contrast(AppColors.primaryDark, Colors.white), greaterThanOrEqualTo(4.5));
    expect(_contrast(AppColors.primaryDark, AppColors.primarySoft), greaterThanOrEqualTo(4.5));
  });
}
