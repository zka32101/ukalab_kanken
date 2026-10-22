import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_common_kit/app_common_kit.dart' show EntitlementOffer;
import 'package:kanken/providers/purchases_provider.dart';
import 'package:kanken/screens/paywall_screen.dart';
import 'package:ukalab_core/ui.dart'
    show PremiumBenefitsCard, PremiumBenefitsStrings;
import 'package:ukalab_core/ukalab_core.dart' show PremiumFeature;

void main() {
  testWidgets('プランの画面に、プレミアムでできること(資格専用キャラを含む)が出る', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        hasAdsRemovedProvider.overrideWith((ref) => Stream.value(false)),
        hasPremiumProvider.overrideWith((ref) => Stream.value(false)),
        availableOffersProvider.overrideWith((ref) async => const [
              EntitlementOffer(
                  id: 'premium',
                  productId: 'kanken_premium',
                  title: 'プレミアム',
                  priceString: '¥1,500（税込・買い切り）'),
            ]),
      ],
      child: const MaterialApp(home: PaywallScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(PremiumBenefitsCard), findsOneWidget);
    final s = PremiumBenefitsStrings.ja;
    expect(find.text(s.title), findsOneWidget);
    for (final f in kKankenPremiumFeatures) {
      expect(find.byKey(ValueKey('premiumBenefit_${f.name}')), findsOneWidget,
          reason: f.name);
    }
    expect(find.byKey(const ValueKey('premiumBenefit_qualificationCharacter')),
        findsOneWidget);
    // このアプリで未提供の機能と、core の「無料のまま」一文は出さない
    for (final f in [
      PremiumFeature.weakDrill,
      PremiumFeature.mockExamHistory,
      PremiumFeature.customMockExam,
      PremiumFeature.readingReadAloud,
    ]) {
      expect(find.byKey(ValueKey('premiumBenefit_${f.name}')), findsNothing,
          reason: f.name);
    }
    expect(find.byKey(const ValueKey('premiumFreeNote')), findsNothing);
    expect(find.text(kKankenPremiumNote), findsOneWidget);
  });

  test('説明の文言に「公式」「合格保証」「価格」を含まない', () {
    final s = PremiumBenefitsStrings.ja;
    final texts = [
      for (final f in kKankenPremiumFeatures) ...[
        s.benefits[f]!.name,
        s.benefits[f]!.description
      ],
      kKankenPremiumNote,
    ].join();
    for (final w in ['公式', '合格保証', '必ず合格', '円']) {
      expect(texts.contains(w), isFalse, reason: w);
    }
  });
}
