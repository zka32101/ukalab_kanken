import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_common_kit/app_common_kit.dart';
import '../providers/purchases_provider.dart';
import '../services/purchase_tiers.dart';
import '../theme/app_theme.dart';
import 'package:app_common_kit/parental_gate.dart';
import 'package:ukalab_core/ui.dart' show PremiumBenefitsCard;
import 'package:ukalab_core/ukalab_core.dart' show PremiumFeature;
import 'package:kanken/widgets/text_fit.dart';

/// このアプリで実際にプレミアム限定になっている機能(core の [PremiumFeature] のうち)。
/// 弱点ドリルなどは未提供のため載せない。
const List<PremiumFeature> kKankenPremiumFeatures = [
  PremiumFeature.examEveMode,
  PremiumFeature.tenMinutePlan,
  PremiumFeature.historyExport,
  PremiumFeature.qualificationCharacter,
];

/// 一覧の下の補足(準1級・1級、広告の非表示、無料版の回数制限の解除)。
const String kKankenPremiumNote = 'プレミアムには、準1級・1級の問題と、広告の非表示、'
    '模擬試験・今日の復習の回数制限の解除も含まれます。';

/// 購入画面。買い切りの2種で、広告なしと、準1級・1級も学べるプレミアム。
/// 価格はストア（RevenueCat）の商品から表示する。
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsRemoved = ref.watch(hasAdsRemovedProvider);
    final premium = ref.watch(hasPremiumProvider);
    final packagesAsync = ref.watch(availableOffersProvider);
    final purchaseState = ref.watch(purchaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('プラン'),
        centerTitle: true,
      ),
      body: adsRemoved.when(
        data: (hasAdsRemoved) {
          final hasPremium = premium.valueOrNull ?? false;
          if (hasPremium) {
            return _buildAlreadyPremium(context);
          }
          return _buildPaywallContent(
            context,
            ref,
            packagesAsync,
            purchaseState,
            hasAdsRemoved: hasAdsRemoved,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
      ),
    );
  }

  Widget _buildAlreadyPremium(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, size: 72, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'ご購入ありがとうございます！',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'プレミアムが有効です。広告なしで学習でき、準1級・1級も利用できます。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywallContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<EntitlementOffer>> packagesAsync,
    AsyncValue<bool> purchaseState, {
    required bool hasAdsRemoved,
  }) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        packagesAsync.when(
          data: (packages) {
            if (packages.isEmpty) {
              return _buildUnavailableNotice();
            }
            final byTier = splitOffersByTier(packages);
            final noAds = byTier[PlanTier.noAds]!;
            final premium = byTier[PlanTier.premium]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (premium.isNotEmpty)
                  _buildTierSection(
                    context,
                    ref,
                    icon: Icons.workspace_premium,
                    title: 'プレミアム',
                    description: '準1級・1級の問題が学べます。広告も表示されません。1回の購入でずっと使えます。',
                    offers: premium,
                  ),
                if (noAds.isNotEmpty && !hasAdsRemoved)
                  _buildTierSection(
                    context,
                    ref,
                    icon: Icons.block,
                    title: '広告なし',
                    description: '演習中のバナー広告・インタースティシャル広告が表示されなくなります。1回の購入でずっと使えます。',
                    offers: noAds,
                  ),
                if (hasAdsRemoved)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      '広告なしを購入済みです。プレミアムにすると準1級・1級も学べます。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => _buildUnavailableNotice(),
        ),
        const SizedBox(height: 12),
        // このアプリで実際にプレミアム限定の機能だけを載せる(準1級・1級は上のプレミアムの説明と補足に書く)。
        const PremiumBenefitsCard(
          key: ValueKey('premiumBenefitsCard'),
          features: kKankenPremiumFeatures,
          showFreeNote: false,
        ),
        const Padding(
          key: ValueKey('premiumBenefitsNote'),
          padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(kKankenPremiumNote, style: TextStyle(fontSize: 12, height: 1.6)),
        ),
        Center(
          child: TextButton(
            onPressed: purchaseState.isLoading
                ? null
                : () async {
                    await ref.read(purchaseProvider.notifier).restore();
                    if (context.mounted) {
                      final restored = ref.read(purchaseProvider).valueOrNull ?? false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(restored ? '購入を復元しました' : '復元できる購入が見つかりませんでした'),
                        ),
                      );
                    }
                  },
            child: const Text('購入を復元する'),
          ),
        ),
      ],
    );
  }

  Widget _buildTierSection(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String description,
    required List<EntitlementOffer> offers,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(icon, size: 28, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          for (final offer in offers) _buildPlanCard(context, ref, offer),
        ],
      ),
    );
  }

  Widget _buildUnavailableNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '現在プランを取得できません。しばらくしてから再度お試しください。',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54, fontSize: 13),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, WidgetRef ref, EntitlementOffer offer) {
    final isPremium = tierOfOffer(offer) == PlanTier.premium;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPremium ? BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? 'プレミアム（買い切り）' : '広告なし（買い切り）',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.priceString,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: ref.watch(purchaseProvider).isLoading
                  ? null
                  : () async {
                      final passedGate = await requireParentalGate(context);
                      if (!passedGate || !context.mounted) return;
                      await ref.read(purchaseProvider.notifier).purchaseOffer(offer.id);
                      final success = ref.read(purchaseProvider).valueOrNull ?? false;
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ご購入ありがとうございます！')),
                        );
                      }
                    },
              child: const Text('購入'),
            ),
          ],
        ),
      ),
    );
  }
}
