import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ukalab_core.dart' show PeerStatsSettings;

import '../models/level_progress.dart';
import '../services/oshi_progress_store.dart';

/// PeerStats（匿名集計）の下準備。**送信は一切しない**。
///
/// (a) 端末内の値を取り出す関数と (b) 参加設定の保存だけを持つ。
/// どちらもどこにも接続しない（PeerStatsSink・installId・Firestore は未実装）。
/// 設定は uid や users/ 配下のデータとは紐付けず、端末内の shared_preferences のみに置く。

/// 延べ回答数。既存の級別集計（levelStats.totalCount）の合計で、
/// 同じ問題を複数回解いた分も数える。
int peerTotalAnswers(Map<String, LevelProgress> stats) =>
    stats.values.fold<int>(0, (sum, p) => sum + p.totalCount);

/// ユニーク問題数。端末内の「解いた問題ID」記録（[OshiProgressStore]）の級ごとの合計。
///
/// 注意：この記録は推し成長機能の導入以降の回答分だけで、過去分は含まない。
/// つまり実際より少なくなりうる（下限値）。送信に使う前に扱いを決める必要がある。
Future<int> peerDistinctQuestions({
  required String profileId,
  required Iterable<String> levels,
}) async {
  var sum = 0;
  for (final level in levels) {
    sum += await OshiProgressStore.answeredCount(
        profileId: profileId, level: level);
  }
  return sum;
}

/// 連続学習日数（既存の `User.streakCount`）をそのまま返す。
int peerStreakDays(int streakCount) => streakCount;

/// 参加設定の保存先（shared_preferences）。既定は OFF。キーはアプリ固有。
class SharedPrefsPeerStatsSettings implements PeerStatsSettings {
  static const key = 'ukalab_kanken_peer_stats_sharing_v1';

  @override
  Future<bool> isSharingEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setSharingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);
  }
}

final peerStatsSettingsProvider =
    Provider<PeerStatsSettings>((ref) => SharedPrefsPeerStatsSettings());
