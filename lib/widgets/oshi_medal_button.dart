import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart'
    show
        MascotStage,
        OshiMedal,
        OshiMedalView,
        Outfit,
        coinProvider,
        coinServiceProvider,
        equippedOutfitProvider,
        selectedCharacterPackProvider,
        showOshiMedalDialog;

import '../models/achievement.dart';
import '../models/user.dart';
import '../providers/achievement_provider.dart';
import '../providers/oshi_provider.dart';
import '../services/oshi_medals.dart';
import '../viewmodels/user_viewmodel.dart';
import 'oshi_card.dart' show shareCardImage;
import 'oshi_readiness_card.dart' show kankenLevelNumber, mockPassedInLedger;
import 'parental_gate_dialog.dart' show requireParentalGate;

/// ホームの推しカードの下に置く「メダルを見る・共有」。
/// 連続学習・模擬試験・実績から作ったメダルを選び、共有カードを開く。
/// 保存は共有シート経由。**外部へ共有する前に必ず保護者ゲートを通す**。
class OshiMedalButton extends ConsumerWidget {
  const OshiMedalButton({
    super.key,
    this.shareImage = shareCardImage,
    this.gate = requireParentalGate,
    this.now,
  });

  /// 画像の共有処理（テストで差し替える）。
  final Future<void> Function(Uint8List png) shareImage;

  /// 保護者ゲート（テストで差し替える）。通ったら true。
  final Future<bool> Function(BuildContext context) gate;

  /// カードに出す日付（テスト用）。
  final DateTime? now;

  Future<List<OshiMedal>> _medals(WidgetRef ref) async {
    User? user;
    try {
      user = await ref.read(currentUserProvider.future);
    } catch (_) {}
    var achievements = const <Achievement>[];
    try {
      achievements = await ref.read(userAchievementsProvider.future);
    } catch (_) {}
    var mockPassed = false;
    try {
      final level = kankenLevelNumber(ref.read(currentLevelProvider));
      mockPassed = mockPassedInLedger(ref.read(coinServiceProvider).ledger, level);
    } catch (_) {}
    return buildOshiMedals(
      streakDays: user?.streakCount ?? 0,
      mockPassed: mockPassed,
      achievements: achievements,
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final medals = await _medals(ref);
    if (!context.mounted) return;
    if (medals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('まだメダルがありません。学習を続けるともらえます')),
      );
      return;
    }
    final picked = await showModalBottomSheet<OshiMedal>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('もらったメダル')),
            for (final m in medals)
              ListTile(
                leading: OshiMedalView(medal: m, size: 40),
                title: Text(m.label),
                onTap: () => Navigator.of(ctx).pop(m),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    var stage = MascotStage.lv1;
    try {
      stage = await ref.read(oshiStageProvider.future);
    } catch (_) {}
    Outfit? outfit;
    try {
      outfit = ref.read(equippedOutfitProvider);
    } catch (_) {}
    if (!context.mounted) return;
    await showOshiMedalDialog(
      context,
      medal: picked,
      pack: ref.read(selectedCharacterPackProvider),
      stage: stage,
      outfit: outfit,
      now: now,
      onShare: (png) async {
        // 外部共有の前に保護者ゲート。通らなければ何も共有しない。
        if (!context.mounted) return;
        if (!await gate(context)) return;
        await shareImage(png);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(coinProvider); // 合格のコインが付いたら（次に開くとき）反映されるよう購読しておく
    return TextButton.icon(
      icon: const Icon(Icons.military_tech_outlined),
      label: const Text('メダルを見る・共有'),
      onPressed: () => _open(context, ref),
    );
  }
}
