import 'package:flutter/material.dart';
import 'package:ukalab_core/ui.dart' show UkalabStartupSplash;

/// 端末側の起動画面の背景色（colors.xml の `splash_background`）と同じ値。
const kankenSplashBackground = Color(0xFFAE2A66);

/// 起動中の読み込み画面（中央にアプリのアイコンと進行表示、下部に組織ロゴ）。
///
/// うかラボ共通の [UkalabStartupSplash]（ukalab_core）に、漢検のアイコンと背景色を渡したもの。
/// 端末側の起動画面（ブランド色+中央に「漢」。`launch_background.xml` / `values-v31`）と同じ背景色にして、
/// アプリの画像と組織ロゴが「一枚の画面」として見えるようにする。
/// 初期化（Firebase・課金・広告など）が終わる前に出す。
Widget kankenStartupSplash() => const UkalabStartupSplash(
      iconAsset: 'assets/branding/app_icon.png',
      backgroundColor: kankenSplashBackground,
    );
