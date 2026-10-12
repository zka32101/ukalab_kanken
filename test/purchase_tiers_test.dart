import 'package:app_common_kit/app_common_kit.dart' show EntitlementOffer;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/services/purchase_tiers.dart';

EntitlementOffer _o(String productId) =>
    EntitlementOffer(id: productId, productId: productId, title: productId, priceString: '¥0');

void main() {
  test('商品IDから段階を決める（広告なしの既存商品は premium を含んでもプレミアムではない）', () {
    expect(tierOfProduct('premium-monthly'), PlanTier.noAds);
    expect(tierOfProduct('premium-yearly'), PlanTier.noAds);
    expect(tierOfProduct('premium-plus-monthly'), PlanTier.premium);
    expect(tierOfProduct('premium-plus-yearly'), PlanTier.premium);
  });

  test('年額かどうかは yearly で決める', () {
    expect(isYearlyProduct('premium-yearly'), isTrue);
    expect(isYearlyProduct('premium-plus-yearly'), isTrue);
    expect(isYearlyProduct('premium-plus-monthly'), isFalse);
  });

  test('商品を段階ごとに分け、段階の中の並びは保つ', () {
    final split = splitOffersByTier([
      _o('premium-plus-monthly'),
      _o('premium-monthly'),
      _o('premium-plus-yearly'),
      _o('premium-yearly'),
    ]);
    expect([for (final o in split[PlanTier.premium]!) o.productId], ['premium-plus-monthly', 'premium-plus-yearly']);
    expect([for (final o in split[PlanTier.noAds]!) o.productId], ['premium-monthly', 'premium-yearly']);
  });

  test('商品が無ければどちらも空', () {
    final split = splitOffersByTier(const []);
    expect(split[PlanTier.premium], isEmpty);
    expect(split[PlanTier.noAds], isEmpty);
  });
}
