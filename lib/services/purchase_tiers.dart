import 'package:app_common_kit/app_common_kit.dart' show EntitlementOffer;

/// 購入プランの段階。広告なし（`noads`）と、準1級・1級も使えるプレミアム（`premium`）。
/// どちらも買い切り（他のうかラボと同じ。方針 D3）。
enum PlanTier { noAds, premium }

/// RevenueCat の Offering「default」のパッケージID。プレミアムは `premium`、広告なしは `noads`
/// （kit の既定の権利IDと同じ。商品は `kanken_premium` / `kanken_noads`）。
const premiumOfferId = 'premium';

/// 商品（パッケージ）から段階を決める。
PlanTier tierOfOffer(EntitlementOffer offer) =>
    offer.id == premiumOfferId ? PlanTier.premium : PlanTier.noAds;

/// 商品を段階ごとに分ける。各段階の中は元の並びのまま。
Map<PlanTier, List<EntitlementOffer>> splitOffersByTier(List<EntitlementOffer> offers) => {
      for (final tier in PlanTier.values)
        tier: [for (final o in offers) if (tierOfOffer(o) == tier) o],
    };
