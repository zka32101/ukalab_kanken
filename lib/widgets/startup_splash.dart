import 'package:app_common_kit/app_common_kit.dart' as kit;
import 'package:flutter/material.dart';

/// 端末側の起動画面の背景色（colors.xml の `splash_background`）と同じ値。
const kankenSplashBackground = Color(0xFFAE2A66);

/// 起動中の読み込み画面（中央にアプリのアイコンと進行表示、下部に組織ロゴ）。
///
/// 共通基盤（app_common_kit）の `StartupSplash` に、漢検のアイコンと背景色を渡したもの。
/// 端末側の起動画面（ブランド色+中央に「漢」。`launch_background.xml` / `values-v31`）と同じ背景色にして、
/// アプリの画像と組織ロゴが「一枚の画面」として見えるようにする。
/// 初期化（Firebase・課金・広告など）が終わる前に出す。
Widget kankenStartupSplash() => const kit.StartupSplash(
      appIconAsset: 'assets/branding/app_icon.png',
      backgroundColor: kankenSplashBackground,
    );
