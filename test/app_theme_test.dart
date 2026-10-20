import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/theme/app_theme.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  test('共通テーマ（言語・教育・漢字検定）の標準呼び出しと同じ配色になる', () {
    final l = AppTheme.light();
    final d = AppTheme.dark();
    final expectLight =
        UkalabTheme.light(field: UkalabField.lang, cert: UkalabCert.kanjiKentei).colorScheme;
    final expectDark =
        UkalabTheme.dark(field: UkalabField.lang, cert: UkalabCert.kanjiKentei).colorScheme;
    expect(l.brightness, Brightness.light);
    expect(d.brightness, Brightness.dark);
    expect(l.colorScheme, expectLight);
    expect(d.colorScheme, expectDark);
    expect(l.colorScheme.primary, UkalabCert.kanjiKentei.light);
    expect(d.colorScheme.primary, UkalabCert.kanjiKentei.dark);
    expect(AppColors.primary, l.colorScheme.primary, reason: '機能色の primary もテーマと同じ');
  });

  test('同梱フォント（BIZ UDPゴシック）が全文字スタイルに指定される', () {
    for (final t in [AppTheme.light(), AppTheme.dark()]) {
      expect(t.textTheme.bodyMedium?.fontFamily, kAppFontFamily);
      expect(t.textTheme.titleLarge?.fontFamily, kAppFontFamily);
      expect(t.textTheme.labelLarge?.fontFamily, kAppFontFamily);
      expect(t.primaryTextTheme.titleLarge?.fontFamily, kAppFontFamily);
    }
    expect(kAppFontFamily, 'BIZUDPGothic');
  });

  test('ボタンのタップ領域は 44pt 以上', () {
    final t = AppTheme.light();
    final s = t.elevatedButtonTheme.style;
    final fromElevated = s?.minimumSize?.resolve({})?.height;
    final fromFilled = t.filledButtonTheme.style?.minimumSize?.resolve({})?.height;
    expect(fromElevated ?? fromFilled, greaterThanOrEqualTo(44));
  });
}
