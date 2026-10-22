import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart'
    show UkalabCert, characterAppIdProvider, characterPremiumProvider;

import '../providers/purchases_provider.dart';

/// 資格専用キャラ（タツ）のための、このアプリのID。ukalab_core の `appIds` と同じ綴り（資格id）。
/// 推しカードに渡す `appId: 'kanken'`（コイン・保存キーのアプリ識別子）とは別物。
final String kCharacterAppId = UkalabCert.kanjiKentei.id;

/// 資格専用キャラの出し分けに必要な override。
/// プレミアムかどうかは、このアプリの権利状態（[hasPremiumProvider]）に追従する。
final List<Override> characterOverrides = [
  characterAppIdProvider.overrideWithValue(kCharacterAppId),
  characterPremiumProvider.overrideWith(
    (ref) => ref.watch(hasPremiumProvider).valueOrNull ?? false,
  ),
];
