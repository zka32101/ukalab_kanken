import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kanken/models/collection_badge.dart';
import 'package:kanken/services/firestore_service.dart';
import 'package:kanken/viewmodels/services_provider.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart' show currentUserIdProvider;
import 'package:kanken/views/collection_badge_screen.dart';

/// コレクション画面が「読み込みのまま」にならない（build の中で毎回 FutureProvider を作り直して
/// いたため、読み込みが終わっても再描画のたびに読み込み中へ戻っていた）ことの確認。
class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class _BadgeFirestore extends FirestoreService {
  _BadgeFirestore(this.badges) : super(firestore: _MockFirebaseFirestore());
  final List<CollectionBadge> badges;
  int calls = 0;

  @override
  Future<List<CollectionBadge>> getUserBadges(String uid, {String profileId = 'default'}) async {
    calls++;
    return badges;
  }
}

CollectionBadge _badge(String level) => CollectionBadge(
      badgeId: 'b_$level',
      name: '$levelマスター',
      description: 'テスト用',
      rarity: BadgeRarity.common,
      category: BadgeCategory.achievement,
      iconEmoji: '🏅',
      requiredCount: 1,
      conditionText: 'テスト用',
      createdAt: DateTime(2026, 10, 23),
      level: level,
    );

void main() {
  Future<_BadgeFirestore> pumpScreen(WidgetTester tester, List<CollectionBadge> badges) async {
    tester.view.physicalSize = const Size(360 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final fs = _BadgeFirestore(badges);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        firestoreServiceProvider.overrideWithValue(fs),
        currentUserIdProvider.overrideWithValue('u1'),
      ],
      child: const MaterialApp(home: CollectionBadgeScreen()),
    ));
    return fs;
  }

  testWidgets('バッジが無くても、読み込みが終わって画面が出る（ぐるぐるのままにならない）', (tester) async {
    final fs = await pumpScreen(tester, const []);
    // 以前は、読み込み→再描画→別のプロバイダーで読み込み中、を繰り返して、ここで落ち着かなかった。
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('獲得済みバッジ'), findsOneWidget);
    expect(fs.calls, 1, reason: '再描画のたびに読み直さない');
  });

  testWidgets('獲得したバッジがあれば、その数が出る', (tester) async {
    await pumpScreen(tester, [_badge('LEVEL_10'), _badge('LEVEL_9')]);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('2'), findsWidgets);
    expect(find.text('獲得済みバッジ'), findsOneWidget);
  });

  testWidgets('上のバーは濃い紫の背景に白い文字（実機で読みにくかった）', (tester) async {
    await pumpScreen(tester, const []);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final bar = tester.widget<AppBar>(find.byType(AppBar));
    expect(bar.backgroundColor, Colors.deepPurple);
    expect(bar.foregroundColor, Colors.white);
  });

  testWidgets('再描画しても、読み込みに戻らない', (tester) async {
    final fs = await pumpScreen(tester, [_badge('LEVEL_8')]);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    }
    expect(fs.calls, 1);
  });

  testWidgets('残りの数は、バッジの全種類（級ごと）から数える（獲得数が6を超えても負にならない）', (tester) async {
    final all = CollectionBadgeScreen.badgeInfoMap.keys.toList();
    await pumpScreen(tester, [for (final l in all) _badge(l)]);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('-${all.length - 6}'), findsNothing);
    expect(find.text('0'), findsWidgets); // 残り 0
  });
}
