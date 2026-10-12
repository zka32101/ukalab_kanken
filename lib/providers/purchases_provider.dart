import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_common_kit/app_common_kit.dart';
import '../services/purchases_service.dart';

/// 広告非表示（サブスク加入中）かどうか。
/// RevenueCat未設定（APIキー未差し替え）の間は常にfalse＝広告表示。
/// 購入・復元・期限切れに追従する（app_common_kit の権利状態）。
final hasAdsRemovedProvider = StreamProvider<bool>((ref) async* {
  final entitlement = PurchasesService.entitlement;
  yield entitlement?.state.adsHidden ?? false;
  if (entitlement != null) {
    yield* entitlement.stateStream.map((s) => s.adsHidden);
  }
});

/// プレミアム（準1級・1級＋広告なし）を持っているか。
/// RevenueCat未設定の間は常にfalse。購入・復元・期限切れに追従する。
final hasPremiumProvider = StreamProvider<bool>((ref) async* {
  final entitlement = PurchasesService.entitlement;
  yield entitlement?.state.hasPremium ?? false;
  if (entitlement != null) {
    yield* entitlement.stateStream.map((s) => s.hasPremium);
  }
});

/// 購入可能な商品一覧（広告なし・プレミアム、それぞれ月額・年額プラン）
final availableOffersProvider = FutureProvider<List<EntitlementOffer>>((ref) async {
  return PurchasesService.getOffers();
});

/// 購入処理の状態管理
final purchaseProvider =
    StateNotifierProvider<PurchaseNotifier, AsyncValue<bool>>(
  (ref) => PurchaseNotifier(ref),
);

class PurchaseNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;
  PurchaseNotifier(this._ref) : super(const AsyncValue.data(false));

  Future<void> purchaseOffer(String offerId) async {
    state = const AsyncValue.loading();
    try {
      final success = await PurchasesService.purchaseOffer(offerId);
      state = AsyncValue.data(success);
      if (success) {
        _ref.invalidate(hasAdsRemovedProvider);
        _ref.invalidate(hasPremiumProvider);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> restore() async {
    state = const AsyncValue.loading();
    try {
      final success = await PurchasesService.restorePurchases();
      state = AsyncValue.data(success);
      if (success) {
        _ref.invalidate(hasAdsRemovedProvider);
        _ref.invalidate(hasPremiumProvider);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(false);
  }
}
