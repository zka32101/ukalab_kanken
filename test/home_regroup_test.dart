import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/providers/achievement_provider.dart';
import 'package:kanken/providers/oshi_provider.dart';
import 'package:kanken/providers/ranking_provider.dart';
import 'package:kanken/providers/spaced_repetition_provider.dart';
import 'package:kanken/router/app_router.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart';
import 'package:kanken/screens/level_hub_screen.dart';
import 'package:kanken/views/home_screen.dart';
import 'package:kanken/widgets/home_group.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';

/// 遷移先は Navigator.push（goX() 拡張）。画面の中身は作らず、遷移先のルート名だけ表示する。
Widget _app() {
  kankenPageOverride = (route, extra) => Scaffold(body: Text('page:$route'));
  // 同じテスト内で何度も開き直すため、毎回新しい木にする（前回積んだ画面を持ち越さない）。
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      coinServiceProvider
          .overrideWithValue(CoinService(store: InMemoryCoinStore())),
      outfitServiceProvider
          .overrideWithValue(OutfitService(store: InMemoryOutfitStore())),
      oshiStageProvider.overrideWith((ref) async => MascotStage.lv1),
      userAchievementsProvider.overrideWith((ref) async => []),
      currentUserIdProvider.overrideWith((ref) => null),
      currentUserProvider.overrideWith((ref) async => null),
      reviewReminderCheckProvider.overrideWith((ref) async {}),
      rankingProvider.overrideWith((ref, filter) async => []),
      practiceQuestionsProvider.overrideWith((ref, level) async => []),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

Future<void> _pump(WidgetTester t, Widget w,
    {double width = 400, double textScale = 1.0}) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = Size(width, 900);
  t.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
    t.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await t.pumpWidget(w);
  await t.pump();
  await t.pump(const Duration(milliseconds: 100));
}

/// 推しカードなどの常時アニメーションがあるため、pumpAndSettle は使わない。
Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
}

Future<void> _open(WidgetTester t, String title) async {
  await _settle(t); // 開閉のアニメーションが終わってから位置を決める
  final f = find.text(title).first;
  await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await t.ensureVisible(f);
  await t.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => kankenPageOverride = null);

  testWidgets('各グループの見出しが表示される', (t) async {
    await _pump(t, _app());
    for (final h in ['今日やること', '記録', '試験に向けて', '設定・その他']) {
      await _open(t, h);
      expect(find.widgetWithText(HomeSectionHeader, h), findsOneWidget);
    }
    // 道具・ソーシャルは、学ぶタブ・記録タブに移した。ホームには出ない。
    expect(find.text('道具'), findsNothing);
    expect(find.text('ソーシャル'), findsNothing);
  });

  testWidgets('今日やることに、12級の一覧が出る（級を選んでから、やることを選ぶ）', (t) async {
    await _pump(t, _app());
    await _open(t, '級を選ぶ');
    for (final level in HomeScreen.levels) {
      await _open(t, HomeScreen.levelNames[level]!);
      expect(find.byKey(ValueKey('levelCard_$level')), findsOneWidget,
          reason: level);
    }
    // 演習・漢字の学習・復習などは、級の画面の中に移した。ホームには出ない。
    expect(find.text('演習を始める'), findsNothing);
    expect(find.text('漢字の学習'), findsNothing);
  });

  testWidgets('級カードに、達成度の2つの印（漢字・問題）が出る。1級にも問題がある', (t) async {
    await _pump(t, _app());
    final kanji = find.byKey(const ValueKey('achievementKanji_LEVEL_10'));
    await t.scrollUntilVisible(kanji, 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.descendant(of: kanji, matching: find.text('漢字 0%')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('achievementQuestion_LEVEL_10')),
            matching: find.text('問題 0%')),
        findsOneWidget);
    final pre = find.byKey(const ValueKey('achievementQuestion_LEVEL_1'));
    await t.scrollUntilVisible(pre, 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.descendant(of: pre, matching: find.text('問題 0%')),
        findsOneWidget);
  });

  testWidgets('級をタップすると、その級の画面（漢字学習・演習・模擬試験・苦手と復習）に進む', (t) async {
    await _pump(t, _app());
    final card = find.byKey(const ValueKey('levelCard_LEVEL_10'));
    await t.scrollUntilVisible(card, 200,
        scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(card);
    await t.tap(card);
    await _settle(t);
    expect(find.byType(LevelHubScreen), findsOneWidget);
    for (final title in [
      '漢字学習',
      '演習',
      '模擬試験',
      '苦手漢字モード',
      '復習（間隔反復）',
      '間違いノート'
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('準1級・1級は、プレミアムでなければ案内が出て、級の画面には進まない', (t) async {
    await _pump(t, _app());
    final card = find.byKey(const ValueKey('levelCard_LEVEL_1_PRE'));
    await t.scrollUntilVisible(card, 200,
        scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(card);
    await t.tap(card);
    await _settle(t);
    expect(find.text('準1級はプレミアム限定です'), findsOneWidget);
    expect(find.byType(LevelHubScreen), findsNothing);
  });

  testWidgets('既存の入口をタップして遷移できる（ホームに残るもの）', (t) async {
    const entries = {
      '学習計画': '/learning-plan',
      '学習目標': '/learning-goals',
    };
    for (final e in entries.entries) {
      SharedPreferences.setMockInitialValues({}); // 毎回、初期状態から
      await _pump(t, _app());
      await _open(t, e.key);
      await t.tap(find.text(e.key));
      await _settle(t);
      expect(find.text('page:${e.value}'), findsOneWidget, reason: e.key);
    }
  });

  testWidgets('設定・その他は常に表示され、設定とプランに遷移できる', (t) async {
    for (final e in {'設定': '/settings', 'プラン': '/paywall'}.entries) {
      await _pump(t, _app());
      await _open(t, e.key);
      await t.tap(find.text(e.key));
      await _settle(t);
      expect(find.text('page:${e.value}'), findsOneWidget);
    }
  });

  testWidgets('折りたたみの開閉が保存される', (t) async {
    await _pump(t, _app());
    await _open(t, '試験に向けて');
    final p = await SharedPreferences.getInstance();
    // 最初は展開（保存なし）。タップで閉じると保存される。
    await t.tap(find.widgetWithText(HomeSectionHeader, '試験に向けて'));
    await _settle(t);
    expect(p.getBool('ukalab_kanken_home_section_exam'), isFalse);

    // 作り直しても閉じたまま
    await _pump(t, _app());
    await _settle(t);
    expect(find.widgetWithText(HomeSectionHeader, '試験に向けて'), findsOneWidget);
    expect(p.getBool('ukalab_kanken_home_section_exam'), isFalse);
  });

  testWidgets('狭い幅と大きい文字でもオーバーフローしない', (t) async {
    await _pump(t, _app(), width: 320, textScale: 2.0);
    await _open(t, '級を選ぶ');
    await _open(t, '準1級（大学・一般程度）');
    await _open(t, '設定・その他');
    expect(t.takeException(), isNull);
  });

  testWidgets('HomeGroup は折りたたみ不可なら常に中身を出す', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: HomeGroup(
          id: 'x',
          title: 'テスト',
          collapsible: false,
          child: Text('中身'),
        ),
      ),
    ));
    expect(find.text('テスト'), findsOneWidget);
    expect(find.text('中身'), findsOneWidget);
    expect(find.byType(HomeSection), findsOneWidget);
  });
}
