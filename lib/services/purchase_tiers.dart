import 'package:app_common_kit/app_common_kit.dart' show EntitlementOffer;

/// 購入プランの段階。広告なし（`ad_free`）と、準1級・1級も使えるプレミアム（`premium`）。
enum PlanTier { noAds, premium }

/// プレミアムの商品IDの接頭辞。広告なしの既存商品（`premium-monthly` / `premium-yearly`）は
/// 名前に premium を含むため、`premium-plus` で区別する。
const premiumProductPrefix = 'premium-plus';

/// 商品IDから段階を決める。
PlanTier tierOfProduct(String productId) =>
    productId.startsWith(premiumProductPrefix) ? PlanTier.premium : PlanTier.noAds;

/// 年額プランか。
bool isYearlyProduct(String productId) => productId.contains('yearly');

/// 商品を段階ごとに分ける。各段階の中は元の並びのまま。
Map<PlanTier, List<EntitlementOffer>> splitOffersByTier(List<EntitlementOffer> offers) => {
      for (final tier in PlanTier.values)
        tier: [for (final o in offers) if (tierOfProduct(o.productId) == tier) o],
    };
