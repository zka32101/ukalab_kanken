import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/achievement.dart';
import 'package:kanken/models/user.dart';
import 'package:kanken/providers/achievement_provider.dart';
import 'package:kanken/providers/oshi_provider.dart';
import 'package:kanken/services/oshi_medals.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart';
import 'package:kanken/widgets/oshi_medal_button.dart';
import 'package:kanken/widgets/oshi_readiness_card.dart';
import 'package:ukalab_core/ui.dart';

Achievement _ach(String id, String name, {bool unlocked = true, int points = 50}) => Achievement(
      id: id,
      name: name,
      description: 'd',
      icon: '⭐',
      type: AchievementType.streak,
      points: points,
      isUnlocked: unlocked,
    );

User _user(int streak) => User(
      uid: 'u',
      currentLevel: 'LEVEL_10',
      streakCount: streak,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('buildOshiMedals', () {
    test('何も無ければ空', () {
      expect(buildOshiMedals(streakDays: 6, mockPassed: false), isEmpty);
    });

    test('連続学習は到達した最大の節目だけ（7=銅・30=銀・100=金）', () {
      OshiMedal one(int d) => buildOshiMedals(streakDays: d, mockPassed: false).single;
      expect(one(7).tier, 1);
      expect(one(29).id, 'streak_7');
      expect(one(30).tier, 2);
      expect(one(100).tier, 3);
      expect(one(400).id, 'streak_100');
      expect(one(7).kind, OshiMedalKind.streak);
    });

    test('模擬試験の合格と解除済みの実績だけがメダルになり、画像は付かない', () {
      final medals = buildOshiMedals(
        streakDays: 0,
        mockPassed: true,
        achievements: [_ach('a1', '優秀者', points: 100), _ach('a2', '未解除', unlocked: false)],
      );
      expect(medals.map((m) => m.id), ['mock_pass', 'achievement_a1']);
      expect(medals.last.tier, 2);
      expect(medals.every((m) => m.image == null), isTrue);
    });
  });

  test('kankenLevelNumber は準級を 15・25 にする', () {
    expect(kankenLevelNumber('LEVEL_10'), 10);
    expect(kankenLevelNumber('LEVEL_2_PRE'), 25);
    expect(kankenLevelNumber('LEVEL_1_PRE'), 15);
  });

  group('OshiMedalButton', () {
    Future<void> pump(
      WidgetTester tester, {
      required int streak,
      List<Achievement> achievements = const [],
      Future<void> Function(Uint8List)? onShare,
      required Future<bool> Function(BuildContext) gate,
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          coinServiceProvider.overrideWithValue(CoinService(store: InMemoryCoinStore())),
          outfitServiceProvider.overrideWithValue(OutfitService(store: InMemoryOutfitStore())),
          oshiStageProvider.overrideWith((ref) async => MascotStage.lv2),
          currentUserProvider.overrideWith((ref) async => _user(streak)),
          userAchievementsProvider.overrideWith((ref) async => achievements),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: OshiMedalButton(
              now: DateTime(2026, 10, 13),
              shareImage: onShare ?? (_) async {},
              gate: gate,
            ),
          ),
        ),
      ));
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('メダルが無いときは案内だけ出す', (tester) async {
      await pump(tester, streak: 0, gate: (_) async => true);
      await tester.tap(find.text('メダルを見る・共有'));
      await settle(tester);
      expect(find.text('まだメダルがありません。学習を続けるともらえます'), findsOneWidget);
      expect(find.byType(OshiMedalShareCard), findsNothing);
    });

    testWidgets('保護者ゲートを通ったときだけ共有される', (tester) async {
      final shared = <Uint8List>[];
      var gateCalls = 0;
      var pass = false;
      await pump(
        tester,
        streak: 8,
        achievements: [_ach('a1', '優秀者')],
        onShare: (p) async => shared.add(p),
        gate: (_) async {
          gateCalls++;
          return pass;
        },
      );
      await tester.tap(find.text('メダルを見る・共有'));
      await settle(tester);
      expect(find.text('7日連続で学習'), findsOneWidget);
      expect(find.text('優秀者'), findsOneWidget);
      await tester.tap(find.text('7日連続で学習'));
      await settle(tester);
      expect(find.byType(OshiMedalShareCard), findsOneWidget);
      expect(find.text('画像を保存'), findsNothing);

      // ゲート不通過: 共有されない
      await tester.runAsync(() async {
        await tester.tap(find.text('共有する'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
      });
      expect(gateCalls, 1);
      expect(shared, isEmpty);

      // ゲート通過: 共有される
      pass = true;
      await tester.runAsync(() async {
        await tester.tap(find.text('共有する'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
      });
      expect(gateCalls, 2);
      expect(shared, hasLength(1));
      expect(shared.single.sublist(1, 4), [0x50, 0x4E, 0x47]);
    });
  });
}
