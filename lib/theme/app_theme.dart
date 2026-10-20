import 'package:flutter/material.dart';
import 'package:ukalab_core/ui.dart';

/// 同梱フォント（BIZ UDPゴシック。SIL OFL 1.1）。pubspec.yaml の fonts の family と一致させる。
/// 端末のフォントで漢字の字形が変わるのを防ぐ（他のうかラボアプリと同じ）。
const kAppFontFamily = 'BIZUDPGothic';

/// 機能カテゴリ色など、共通テーマに無い用途の色定義。
///
/// ブランド色は共通テーマの資格別配色（[UkalabCert.kanjiKentei]）から取る。
class AppColors {
  AppColors._();

  // ブランドカラー（共通テーマの漢字検定の配色。ライトの塗り色）。
  // 画面側で固定色として使う箇所（グラデーション等）向け。テーマに乗せられる箇所は
  // Theme.of(context).colorScheme を使うこと。
  static final Color primary = UkalabCert.kanjiKentei.light;
  // 濃い側（グラデーションの終点・タブの選択色）。
  static final Color primaryDark = Color.lerp(primary, const Color(0xFF000000), 0.25)!;
  // 淡い塗り（背景・選択行）。
  static final Color primarySoft = Color.lerp(const Color(0xFFFFFFFF), primary, 0.10)!;

  // 機能カテゴリカラー（意味のグルーピングに基づく統一配色）
  static const Color study = Color(0xFF2FA86A);      // 学習・演習系（緑）
  static const Color analysis = Color(0xFFEA8C2E);   // 分析・計画系（オレンジ）
  static const Color social = Color(0xFF8B5CF6);     // ソーシャル系（紫）
  static const Color reward = Color(0xFFE0A62E);     // コレクション・報酬系（琥珀）
  static const Color info = Color(0xFF2F8FE0);       // 情報・管理系（青）

  // セマンティックカラー
  static const Color success = Color(0xFF2FA86A);
  static const Color warning = Color(0xFFE0A62E);
  static const Color error = Color(0xFFE0453C);

  // 中立色
  static const Color surfaceMuted = Color(0xFFF5F6FA);
  static const Color textMuted = Color(0xFF6B7280);
}

/// アプリ全体のテーマ定義。
///
/// 色・文字サイズ・角丸・タップ領域は、うかラボ共通テーマ
/// （`UkalabTheme.light/dark(field: 言語・教育, cert: 漢字検定)`）の標準呼び出しに従う。
/// 書体は、同梱の BIZ UDPゴシックを textTheme に当てるだけ。
/// [AppColors] は機能カテゴリ（学習・分析・ソーシャルなど）の色として残す。
class AppTheme {
  AppTheme._();

  static const UkalabField field = UkalabField.lang;
  static const UkalabCert cert = UkalabCert.kanjiKentei;

  static ThemeData light() => withAppFont(UkalabTheme.light(field: field, cert: cert));
  static ThemeData dark() => withAppFont(UkalabTheme.dark(field: field, cert: cert));

  /// 同梱フォントを文字スタイルに当てる。
  static ThemeData withAppFont(ThemeData t) => t.copyWith(
        textTheme: t.textTheme.apply(fontFamily: kAppFontFamily),
        primaryTextTheme: t.primaryTextTheme.apply(fontFamily: kAppFontFamily),
        appBarTheme: t.appBarTheme.copyWith(
          titleTextStyle: t.appBarTheme.titleTextStyle?.copyWith(fontFamily: kAppFontFamily),
        ),
      );
}
