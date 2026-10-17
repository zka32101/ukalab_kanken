import 'package:app_common_kit/app_common_kit.dart' show EntitlementOffer;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/services/purchase_tiers.dart';

EntitlementOffer _o(String id, String productId) =>
    EntitlementOffer(id: id, productId: productId, title: id, priceString: '¥0');

void main() {
  test('パッケージIDから段階を決める(premium=プレミアム、それ以外=広告なし)', () {
    expect(tierOfOffer(_o('premium', 'kanken_premium')), PlanTier.premium);
    expect(tierOfOffer(_o('noads', 'kanken_noads')), PlanTier.noAds);
  });

  test('段階ごとに分け、各段階の中は元の並びのまま', () {
    final split = splitOffersByTier([
      _o('noads', 'kanken_noads'),
      _o('premium', 'kanken_premium'),
    ]);
    expect([for (final o in split[PlanTier.premium]!) o.productId], ['kanken_premium']);
    expect([for (final o in split[PlanTier.noAds]!) o.productId], ['kanken_noads']);
  });

  test('空なら両方とも空', () {
    final split = splitOffersByTier(const []);
    expect(split[PlanTier.premium], isEmpty);
    expect(split[PlanTier.noAds], isEmpty);
  });
}
