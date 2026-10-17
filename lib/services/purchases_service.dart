import 'package:app_common_kit/app_common_kit.dart';

/// RevenueCat経由の購入管理（買い切り2種: 広告なし／プレミアム。他のうかラボと同じ。方針 D3）。
///
/// 商品・権利の設定（RevenueCat「うかラボ」プロジェクト。2026-10-17 登録済み）:
///   - Play の1回限りのアイテム `kanken_noads`（¥480）/ `kanken_premium`（¥1,500）
///   - 権利 `noads` に kanken_noads、権利 `premium` に kanken_premium を紐付け
///   - Offering「default」のパッケージ `noads` / `premium` に、それぞれの商品を追加
/// 公開SDKキー（Google）は、ビルド時に `--dart-define=RC_GOOGLE_KEY=goog_...` で渡す
/// （コミットしない。CIは GitHub Actions の Secrets `RC_GOOGLE_KEY`）。
///
/// 旧設定（定期購入 `premium-monthly` / `premium-yearly`、権利 `ad_free`）は使わない。
class PurchasesService {
  /// RevenueCat の公開SDKキー(Google Play 用)。ビルド時に `--dart-define=RC_GOOGLE_KEY=...` で渡す。
  /// 未指定(空)のときは RevenueCat へ接続せず、購入なし・広告は常に表示のまま動く。
  static const String _apiKey = String.fromEnvironment('RC_GOOGLE_KEY');

  static bool _initialized = false;
  static RevenueCatEntitlementService? _entitlement;

  /// 権利状態（app_common_kit）。RevenueCat未設定・初期化失敗時はnull。
  static EntitlementService? get entitlement => _entitlement;

  /// RevenueCat 初期化（main.dartから起動時に一度だけ呼ぶ）
  static Future<void> initialize() async {
    if (_apiKey.isEmpty) {
      // APIキー未指定の間はRevenueCatへ接続しない（クラッシュ防止）。
      // 広告非表示チェックは常にfalse（＝広告表示）として扱われる。
      return;
    }
    try {
      // 権利IDは kit の既定（noads / premium）。購入前の保護者ゲートはペイウォール画面側で実施済み。
      _entitlement = await RevenueCatEntitlementService.init(publicSdkKey: _apiKey);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  static bool get isConfigured => _initialized;

  /// 購入可能な商品（広告なし・プレミアム）を取得
  static Future<List<EntitlementOffer>> getOffers() async =>
      _entitlement?.offers() ?? Future.value(const []);

  /// 商品を購入（購入前の保護者ゲートは呼び出し側の画面で実施済み）
  static Future<bool> purchaseOffer(String offerId) async {
    final entitlement = _entitlement;
    if (entitlement == null) return false;
    return await entitlement.purchaseOffer(offerId) == PurchaseOutcome.success;
  }

  /// 購入の復元
  static Future<bool> restorePurchases() async {
    if (!_initialized) return false;
    try {
      return (await _entitlement!.restore()).adsHidden;
    } catch (_) {
      return false;
    }
  }

  /// 広告が非表示か（広告なし、またはプレミアム）
  static Future<bool> hasAdsRemoved() async {
    if (!_initialized) return false;
    try {
      return _entitlement!.state.adsHidden;
    } catch (_) {
      return false;
    }
  }

  /// プレミアム（準1級・1級を含む）を保持しているか
  static Future<bool> hasPremium() async {
    if (!_initialized) return false;
    try {
      return _entitlement!.state.hasPremium;
    } catch (_) {
      return false;
    }
  }
}
