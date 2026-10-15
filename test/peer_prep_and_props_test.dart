import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/peer_stats_prep.dart';
import 'package:kanken/models/level_progress.dart';
import 'package:kanken/services/oshi_progress_store.dart';
import 'package:kanken/widgets/cert_prop_badge.dart';
import 'package:kanken/widgets/peer_stats_settings_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ukalab_core.dart' show PeerStatsSettings;

class _MemSettings implements PeerStatsSettings {
  bool v = false;
  @override
  Future<bool> isSharingEnabled() async => v;
  @override
  Future<void> setSharingEnabled(bool e) async => v = e;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PeerStatsSettings: 既定OFF・保存・復元・アプリ固有キー', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await SharedPrefsPeerStatsSettings().isSharingEnabled(), isFalse);
    await SharedPrefsPeerStatsSettings().setSharingEnabled(true);
    expect(await SharedPrefsPeerStatsSettings().isSharingEnabled(), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ukalab_kanken_peer_stats_sharing_v1'), isTrue);
    await SharedPrefsPeerStatsSettings().setSharingEnabled(false);
    expect(await SharedPrefsPeerStatsSettings().isSharingEnabled(), isFalse);
  });

  test('延べ回答数は級別集計の合計（既存値と一致）', () {
    final stats = {
      'LEVEL_10': const LevelProgress(level: 'LEVEL_10', correctCount: 5, totalCount: 8),
      'LEVEL_9': const LevelProgress(level: 'LEVEL_9', correctCount: 1, totalCount: 2),
    };
    expect(peerTotalAnswers(stats), 10);
    expect(peerTotalAnswers(const {}), 0);
    expect(peerStreakDays(4), 4);
  });

  test('ユニーク問題数は OshiProgressStore の記録と一致', () async {
    SharedPreferences.setMockInitialValues({});
    for (final id in ['a', 'a', 'b']) {
      await OshiProgressStore.markAnswered(
          profileId: 'p', level: 'LEVEL_10', questionId: id);
    }
    await OshiProgressStore.markAnswered(
        profileId: 'p', level: 'LEVEL_9', questionId: 'c');
    expect(
        await peerDistinctQuestions(
            profileId: 'p', levels: ['LEVEL_10', 'LEVEL_9', 'LEVEL_8']),
        3);
    expect(await OshiProgressStore.answeredCount(profileId: 'p', level: 'LEVEL_10'), 2);
  });

  test('設定スイッチの表示フラグは本番で false', () {
    expect(kPeerStatsSettingsVisible, isFalse);
  });

  testWidgets('設定スイッチ（単体）: 説明文・既定OFF・切り替えで保存', (tester) async {
    final s = _MemSettings();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: PeerStatsSettingsTile(settings: s))));
    await tester.pumpAndSettle();
    expect(find.text('匿名の集計に参加する'), findsOneWidget);
    expect(find.textContaining('連続学習日数・累計の問題数・試験日'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(s.v, isTrue);
  });

  group('CertPropBadge', () {
    testWidgets('狭い幅でもオーバーフローせず画像を出し、装飾のみ', (tester) async {
      tester.view.physicalSize = const Size(240, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          appBar: null,
          body: Row(children: [
            Expanded(child: Text('うかラボ漢字検定 うかラボ漢字検定 うかラボ漢字検定')),
            Padding(padding: EdgeInsets.only(right: 12), child: CertPropBadge()),
          ]),
        ),
      ));
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(ExcludeSemantics), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('画像読込失敗時は非表示にフォールバック', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CertPropBadge())));
      final image = tester.widget<Image>(find.byType(Image));
      final fallback = image.errorBuilder!(tester.element(find.byType(Image)), 'x', null);
      expect(fallback, isA<SizedBox>());
      expect(find.byType(IgnorePointer), findsWidgets);
    });
  });
}
