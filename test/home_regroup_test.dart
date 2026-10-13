import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanken/providers/achievement_provider.dart';
import 'package:kanken/providers/oshi_provider.dart';
import 'package:kanken/providers/ranking_provider.dart';
import 'package:kanken/providers/spaced_repetition_provider.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart';
import 'package:kanken/views/home_screen.dart';
import 'package:kanken/widgets/home_group.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';

const _routes = [
  '/stroke-order',
  '/readings',
  '/glossary',
  '/study-notes',
  '/weak-areas',
  '/learning-plan',
  '/learning-goals',
  '/spaced-repetition-review',
  '/mock-exam-modes',
  '/friends',
  '/settings',
  '/paywall',
];

Widget _app({GoRouter? router}) {
  final r = router ??
      GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        for (final p in _routes)
          GoRoute(path: p, builder: (_, __) => Scaffold(body: Text('page:$p'))),
      ]);
  return ProviderScope(
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
    child: MaterialApp.router(routerConfig: r),
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
  final f = find.text(title).first;
  await t.scrollUntilVisible(f, 200,
      scrollable: find.byType(Scrollable).first);
  await t.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('各グループの見出しが表示される', (t) async {
    await _pump(t, _app());
    for (final h in ['今日やること', '記録', '試験に向けて']) {
      await _open(t, h);
      expect(find.widgetWithText(HomeSectionHeader, h), findsOneWidget);
    }
    for (final h in ['道具', 'ソーシャル', '設定・その他']) {
      await _open(t, h);
      expect(find.widgetWithText(HomeSectionHeader, h), findsOneWidget);
    }
  });

  testWidgets('初回は今日やること・記録・試験に向けてが展開、道具とソーシャルは閉じている', (t) async {
    await _pump(t, _app());
    await _open(t, '苦手分析');
    expect(find.text('苦手分析'), findsOneWidget);
    await _open(t, '学習計画');
    expect(find.text('学習計画'), findsOneWidget);
    expect(find.text('用語集'), findsNothing);
    expect(find.text('フレンド'), findsNothing);
  });

  testWidgets('既存の入口をタップして遷移できる（展開済みのもの）', (t) async {
    const entries = {
      '漢字の学習': '/stroke-order',
      '復習（間隔反復）': '/spaced-repetition-review',
      '苦手分析': '/weak-areas',
      '学習計画': '/learning-plan',
      '学習目標': '/learning-goals',
      '模擬試験モード': '/mock-exam-modes',
    };
    for (final e in entries.entries) {
      await _pump(t, _app());
      await _open(t, e.key);
      await t.tap(find.text(e.key));
      await _settle(t);
      expect(find.text('page:${e.value}'), findsOneWidget, reason: e.key);
    }
  });

  testWidgets('閉じているグループを開くと中の入口に遷移できる', (t) async {
    const entries = {
      '用語集': '/glossary',
      '章ごとの解説読み物': '/readings',
      'ブックマーク・メモ': '/study-notes',
    };
    for (final e in entries.entries) {
      SharedPreferences.setMockInitialValues({}); // 毎回、初期（閉じた）状態から
      await _pump(t, _app());
      await _open(t, '道具');
      await t.tap(find.text('道具'));
      await _settle(t);
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
    await _open(t, '道具');
    await t.tap(find.text('道具'));
    await _settle(t);
    expect(find.text('用語集'), findsOneWidget);
    final p = await SharedPreferences.getInstance();
    expect(p.getBool('ukalab_kanken_home_section_tools'), isTrue);

    // 作り直しても開いたまま
    await _pump(t, _app());
    await _settle(t);
    await _open(t, '用語集');
    expect(find.text('用語集'), findsOneWidget);

    // 閉じる
    await t.tap(find.text('道具'));
    await _settle(t);
    expect(find.text('用語集'), findsNothing);
    expect(p.getBool('ukalab_kanken_home_section_tools'), isFalse);
  });

  testWidgets('狭い幅と大きい文字でもオーバーフローしない', (t) async {
    await _pump(t, _app(), width: 320, textScale: 2.0);
    for (final h in ['道具', 'ソーシャル']) {
      await _open(t, h);
      await t.tap(find.text(h));
      await _settle(t);
    }
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
