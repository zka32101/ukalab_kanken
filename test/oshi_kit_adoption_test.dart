import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/providers/oshi_provider.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart';
import 'package:kanken/widgets/oshi_card.dart';
import 'package:kanken/widgets/oshi_readiness_card.dart';

/// 推しカードのメニュー（着替え・ショップ、試験の結果報告）の配線テスト。
ProviderContainer _container() {
  final coin = CoinService(
    store: InMemoryCoinStore(),
    shop: OutfitCatalog.shopItems([UkalabCert.kanjiKentei]),
  );
  final c = ProviderContainer(overrides: [
    coinServiceProvider.overrideWithValue(coin),
    outfitServiceProvider.overrideWithValue(OutfitService(store: InMemoryOutfitStore())),
    oshiStageProvider.overrideWith((ref) async => MascotStage.lv2),
    currentUserProvider.overrideWith((ref) async => null),
  ]);
  addTearDown(c.dispose);
  return c;
}

/// 推しが常に動いている（アニメーション）ため、pumpAndSettle は終わらない。時間を区切って進める。
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final c = _container();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: OshiCard())),
    ));
    await _settle(tester);
    return c;
  }

  test('漢字検定の衣装がショップに並ぶ（通常衣装は200コイン）', () {
    final items = OutfitCatalog.shopItems([UkalabCert.kanjiKentei]);
    expect(items, hasLength(1));
    expect(items.single.price, OutfitCatalog.regularPrice);
  });

  testWidgets('「着替え・ショップ」で共通の着替え画面が開く', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(PopupMenuButton<Object>).evaluate().isEmpty
        ? find.byIcon(Icons.more_vert)
        : find.byType(PopupMenuButton<Object>));
    await _settle(tester);
    await tester.tap(find.text('着替え・ショップ'));
    await _settle(tester);
    expect(find.byType(WardrobeScreen), findsOneWidget);
    expect(find.text('合格したときに解放されます'), findsOneWidget);
  });

  testWidgets('「試験の結果を報告」で合格を選ぶと、コインと合格記念の衣装が付く', (tester) async {
    final c = await pump(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    await tester.tap(find.text('試験の結果を報告'));
    await _settle(tester);
    await tester.tap(find.text('合格しました'));
    await _settle(tester);
    expect(find.text('共有する'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await _settle(tester);
    expect(c.read(coinProvider).balance, CoinRules.standard.passReport);
    expect(c.read(outfitServiceProvider).passedCerts, contains('kanji_kentei'));
  });

  test('模擬試験の合格は級ごとに分かる（1級と10級を取り違えない）', () async {
    final coin = CoinService(store: InMemoryCoinStore(), shop: const []);
    await coin.grant(CoinEvent.mockPass('kanken_level_10'));
    expect(mockPassedInLedger(coin.ledger, 10), isTrue);
    expect(mockPassedInLedger(coin.ledger, 1), isFalse);
    expect(mockPassedInLedger(coin.ledger, 4), isFalse);
  });

  testWidgets('「準備完了まで」カードが習得度と案内を出す', (tester) async {
    final c = ProviderContainer(overrides: [
        coinServiceProvider.overrideWithValue(
            CoinService(store: InMemoryCoinStore(), shop: const [])),
        oshiMasteryProvider.overrideWith(
            (ref) async => const MasteryInput(coverage: 0.5, accuracy: 0.8)),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: OshiReadinessCard())),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('準備完了まで'), findsOneWidget);
    expect(find.text('習得度があと40%、模擬試験の合格でそろいます'), findsOneWidget);
  });
}
