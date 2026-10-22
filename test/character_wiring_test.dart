import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

import 'package:kanken/data/character_wiring.dart';
import 'package:kanken/providers/purchases_provider.dart';

ProviderContainer _container(bool premium) {
  final c = ProviderContainer(
    overrides: [
      hasPremiumProvider.overrideWith((ref) => Stream.value(premium)),
      ...characterOverrides,
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('appId は kanji_kentei（ukalab_core の tatsu.appIds と同じ綴り）', () {
    final c = _container(false);
    expect(c.read(characterAppIdProvider), 'kanji_kentei');
    expect(
      UkalabCharacters.tatsu.isAvailableIn(c.read(characterAppIdProvider)!),
      isTrue,
    );
  });

  test('無料は false', () async {
    final c = _container(false);
    await c.read(hasPremiumProvider.future);
    expect(c.read(characterPremiumProvider), isFalse);
  });

  test('プレミアムは true', () async {
    final c = _container(true);
    await c.read(hasPremiumProvider.future);
    expect(c.read(characterPremiumProvider), isTrue);
  });

  test('タツは、プレミアムのときだけ選べる', () async {
    final free = _container(false);
    await free.read(hasPremiumProvider.future);
    expect(
      isCharacterUnlocked(
        UkalabCharacters.tatsu,
        appId: free.read(characterAppIdProvider),
        isPremium: free.read(characterPremiumProvider),
      ),
      isFalse,
    );
    final paid = _container(true);
    await paid.read(hasPremiumProvider.future);
    expect(
      isCharacterUnlocked(
        UkalabCharacters.tatsu,
        appId: paid.read(characterAppIdProvider),
        isPremium: paid.read(characterPremiumProvider),
      ),
      isTrue,
    );
  });
}
