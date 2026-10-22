import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/router/app_router.dart';
import 'package:kanken/screens/level_hub_screen.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 遷移先は Navigator.push（goX() 拡張）。遷移先のルート名だけ表示する。
Widget _app(ProviderContainer container, {String level = 'LEVEL_8'}) {
  kankenPageOverride = (route, extra) => Scaffold(body: Text('page:$route'));
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: LevelHubScreen(level: level)),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => kankenPageOverride = null);

  testWidgets('開くと、その級が選ばれた状態になる（漢字学習・演習などは、この級を見て動く）', (t) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(currentLevelProvider), 'LEVEL_10');
    await t.pumpWidget(_app(c, level: 'LEVEL_8'));
    await t.pump();
    expect(c.read(currentLevelProvider), 'LEVEL_8');
  });

  testWidgets('級の名前と、配当漢字の数が出る', (t) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await t.pumpWidget(_app(c, level: 'LEVEL_8'));
    await t.pump();
    expect(find.text('8級（小3）'), findsOneWidget);
    final n = LevelKanjiData.forLevel('LEVEL_8').length;
    expect(find.text('8級の配当漢字は$n字です。'), findsOneWidget);
  });

  const entries = {
    '漢字学習': '/stroke-order',
    '模擬試験': '/mock-exam-modes',
    '苦手漢字モード': '/weak-kanji',
    '復習（間隔反復）': '/spaced-repetition-review',
  };
  for (final e in entries.entries) {
    testWidgets('${e.key}の入口から、${e.value} に進める', (t) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await t.pumpWidget(_app(c));
      await t.pump();
      await t.ensureVisible(find.text(e.key));
      await t.tap(find.text(e.key));
      await t.pumpAndSettle();
      expect(find.text('page:${e.value}'), findsOneWidget);
    });
  }

  testWidgets('演習をタップすると、出題形式を選ぶ画面が出る', (t) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await t.pumpWidget(_app(c));
    await t.pump();
    await t.tap(find.text('演習'));
    await t.pumpAndSettle();
    expect(find.text('出題形式をえらぼう'), findsOneWidget);
    expect(find.text('まぜて出題'), findsOneWidget);
  });

  testWidgets('狭い幅・大きい文字でもオーバーフローしない', (t) async {
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(320, 900);
    t.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
      t.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await t.pumpWidget(_app(c));
    await t.pump();
    expect(t.takeException(), isNull);
  });
}
