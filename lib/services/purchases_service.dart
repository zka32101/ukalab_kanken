import 'package:app_common_kit/app_common_kit.dart';

/// RevenueCat経由のサブスクリプション管理（二段階: 広告なし／プレミアム）。
///
/// 参考実装: H:\マイドライブ\apps\card_rivals\lib\services\purchases_service.dart
///
/// 【要ユーザー対応】
/// RevenueCatダッシュボードで kanken 用の新規Appを作成し、
/// 以下を設定した上で `_apiKey` を実際のPublic SDK Keyに差し替えること:
///   - Google Play Console側でサブスクリプション商品を作成
///     (premium-monthly: 月額¥300 / premium-yearly: 年額¥2,400)
///   - RevenueCatのEntitlement「ad_free」(Display Name: noads)に上記2商品を紐付け
///   - Offering「default」にpremium-monthly/premium-yearlyのPackageを追加
///
/// 【プレミアム（準1級・1級＋広告なし）の追加設定】
///   - 商品を作成（premium-plus-monthly / premium-plus-yearly。価格は仮に月額¥480）
///   - RevenueCatのEntitlement「premium」に上記の商品を紐付け
///   - Offering「default」にpremium-plus-monthly/premium-plus-yearlyのPackageを追加
///   - 既存の2商品の表示名は「広告なし」にする（商品IDは変更不可）
class PurchasesService {
  static const String _apiKey = 'goog_PkCbEBxntkZNsLxCbKeSkHnoWEi';

  /// 広告非表示エンタイトルメント。RevenueCat側のIdentifierは作成後
  /// 変更不可のため'ad_free'のまま。Display Nameのみ'noads'に変更済み
  /// (うかラボ共通方針の意図はDisplay Nameレベルで反映)。
  /// コードが実際に参照するのはIdentifierなので、ここは'ad_free'のまま
  /// にする必要がある(2026-10-01、Identifier変更不可と判明し決定)。
  static const String entitlementNoAds = 'ad_free';
  static const String premiumMonthly = 'premium-monthly';
  static const String premiumYearly = 'premium-yearly';

  /// プレミアム（準1級・1級＋広告なし）のエンタイトルメント。
  static const String entitlementPremium = 'premium';

  static bool _initialized = false;
  static RevenueCatEntitlementService? _entitlement;

  /// 権利状態（app_common_kit）。RevenueCat未設定・初期化失敗時はnull。
  static EntitlementService? get entitlement => _entitlement;

  /// RevenueCat 初期化（main.dartから起動時に一度だけ呼ぶ）
  static Future<void> initialize() async {
    if (_apiKey.startsWith('REPLACE_WITH_')) {
      // APIキー未設定の間はRevenueCatへ接続しない（クラッシュ防止）。
      // 広告非表示チェックは常にfalse（＝広告表示）として扱われる。
      return;
    }
    try {
      // 権利IDはRevenueCat側で変更不可の'ad_free'のため、キット既定のnoadsを上書きする。
      // 購入前の保護者ゲートはペイウォール画面側で実施済み。
      _entitlement = await RevenueCatEntitlementService.init(
        publicSdkKey: _apiKey,
        ids: const EntitlementIds(noAds: entitlementNoAds, premium: entitlementPremium),
      );
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  static bool get isConfigured => _initialized;

  /// 購入可能な商品（月額・年額）を取得
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
