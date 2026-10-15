import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/widgets/startup_splash.dart';

void main() {
  test('端末の起動画面の背景色とアプリ内スプラッシュの背景色が一致する', () {
    final xml = File('android/app/src/main/res/values/colors.xml').readAsStringSync();
    final m = RegExp(r'name="splash_background">#([0-9A-Fa-f]{6})<').firstMatch(xml);
    expect(m, isNotNull);
    expect(kankenSplashBackground.toARGB32() & 0xFFFFFF, int.parse(m!.group(1)!, radix: 16));
  });

  test('Android 12+ の起動画面はアダプティブアイコンの前景を使う', () {
    final xml = File('android/app/src/main/res/values-v31/styles.xml').readAsStringSync();
    expect(xml, contains('windowSplashScreenBackground'));
    expect(xml, contains('@mipmap/ic_launcher_foreground'));
    expect(File('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png').existsSync(), isTrue);
  });

  test('スプラッシュ用アイコンは launcher と同じ 432px の画像', () {
    final b = File('assets/branding/app_icon.png').readAsBytesSync();
    final bd = b.buffer.asByteData();
    expect(bd.getUint32(16), 432);
    expect(bd.getUint32(20), 432);
  });
}
