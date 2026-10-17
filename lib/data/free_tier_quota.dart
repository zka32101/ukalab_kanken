import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ukalab_core.dart';

/// 無料版の回数制限（方針 D6。標準値は、模擬試験が月1回・今日の復習が1日10問。値は暫定で、公開後の実測で見直す）。
/// プレミアム（premium）なら無制限。使用回数は端末内（SharedPreferences）に保存する。
/// 制限は「模擬試験を始める」と「今日の復習」の案内だけにかける（間違いノート・演習は無料のまま）。
class _PrefsKeyValueStore implements KeyValueStore {
  _PrefsKeyValueStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
}

/// 模擬試験の回数制限(月)。
Future<UsageQuota> mockExamQuota({
  required bool isPremium,
  DateTime Function()? clock,
}) async {
  final prefs = await SharedPreferences.getInstance();
  return FreeTierLimits.standard.mockExamQuota(
    isPremium: isPremium,
    store: _PrefsKeyValueStore(prefs),
    clock: clock,
  );
}

/// 「今日の復習」の回数制限(日)。数えるのは、復習の期限が来ていた問題に答えた回数。
Future<UsageQuota> todayReviewQuota({
  required bool isPremium,
  DateTime Function()? clock,
}) async {
  final prefs = await SharedPreferences.getInstance();
  return FreeTierLimits.standard.reviewQuota(
    isPremium: isPremium,
    store: _PrefsKeyValueStore(prefs),
    clock: clock,
  );
}
