import 'package:ukalab_core/ui.dart'
    show
        CoinLedger,
        ReadinessProgressCard,
        ReadinessRule,
        coinProvider,
        coinServiceProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/oshi_provider.dart';
import '../viewmodels/user_viewmodel.dart';

/// この級の模擬試験に合格したことがあるか（学習コインの台帳から分かる）。
/// [level] は級の数字（4 や 10）。1級と10級を取り違えないよう、IDは完全一致で見る。
bool mockPassedInLedger(CoinLedger ledger, int level) {
  final base = 'mockPass|kanken_level_$level';
  return ledger.entries.any(
      (e) => e.kind == 'mockPass' && (e.id == base || e.id.startsWith('$base|')));
}

/// 級の識別子（'LEVEL_4'、'LEVEL_2_PRE' など）を、コイン台帳で使う級の数字にする。
int kankenLevelNumber(String levelString) => levelString == 'LEVEL_2_PRE'
    ? 25
    : levelString == 'LEVEL_1_PRE'
        ? 15
        : int.tryParse(levelString.replaceFirst('LEVEL_', '')) ?? 10;

/// ホームの「準備完了まで」カード。習得度と模擬試験の合格から進み具合を見せる。
class OshiReadinessCard extends ConsumerWidget {
  const OshiReadinessCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mastery = ref.watch(oshiMasteryProvider).valueOrNull;
    if (mastery == null) return const SizedBox.shrink();
    var mockPassed = false;
    try {
      ref.watch(coinProvider); // 合格のコインが付いたら再描画する
      final levelString = ref.watch(currentLevelProvider);
      final level = kankenLevelNumber(levelString);
      mockPassed = mockPassedInLedger(ref.read(coinServiceProvider).ledger, level);
    } catch (_) {}
    return ReadinessProgressCard(
      progress: ReadinessRule.standard.progress(mastery: mastery, mockPassed: mockPassed),
    );
  }
}
