import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/router/app_router.dart';
import 'package:kanken/screens/learn_tab_screen.dart';
import 'package:kanken/screens/record_tab_screen.dart';

/// 段階2: 「学ぶ」「記録」タブの入口は Navigator.push で個別画面へ遷移する。
/// 画面の中身は作らず、遷移先のルート名だけ確かめる。
Future<void> _pump(WidgetTester t, Widget home) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(800, 1600);
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
    kankenPageOverride = null;
  });
  kankenPageOverride = (route, extra) => Scaffold(body: Text('page:$route'));
  await t.pumpWidget(MaterialApp(home: home));
}

void main() {
  testWidgets('学ぶタブの入口が各画面へ遷移する', (t) async {
    const entries = {
      '復習（間隔反復）': '/spaced-repetition-review',
      '漢字の学習': '/stroke-order',
      '苦手漢字モード': '/weak-kanji',
      '章ごとの解説読み物': '/readings',
      '用語集': '/glossary',
      'ブックマーク・メモ': '/study-notes',
    };
    for (final e in entries.entries) {
      await _pump(t, const LearnTabScreen());
      await t.tap(find.text(e.key));
      await t.pumpAndSettle();
      expect(find.text('page:${e.value}'), findsOneWidget, reason: e.key);
    }
  });

  testWidgets('記録タブの入口が各画面へ遷移する（バッジは記録タブ）', (t) async {
    const entries = {
      '進捗': '/progress',
      '学習分析': '/analytics',
      '苦手分析': '/weak-areas',
      '学習計画': '/learning-plan',
      '学習目標': '/learning-goals',
      '模擬試験の履歴': '/exam-history',
      'バッジ': '/collection-badge',
    };
    for (final e in entries.entries) {
      await _pump(t, const RecordTabScreen());
      await t.tap(find.text(e.key));
      await t.pumpAndSettle();
      expect(find.text('page:${e.value}'), findsOneWidget, reason: e.key);
    }
  });

  testWidgets('goHome は積んだ画面をすべて閉じて最初の画面に戻る', (t) async {
    kankenPageOverride = (route, extra) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.goHome(),
              child: Text('back:$route'),
            ),
          ),
        );
    addTearDown(() => kankenPageOverride = null);
    await t.pumpWidget(const MaterialApp(home: LearnTabScreen()));
    await t.tap(find.text('用語集'));
    await t.pumpAndSettle();
    await t.tap(find.text('back:/glossary'));
    await t.pumpAndSettle();
    expect(find.byType(LearnTabScreen), findsOneWidget);
  });
}
