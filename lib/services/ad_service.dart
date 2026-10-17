import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/foundation.dart';

import 'no_ads_backend.dart';
import 'purchases_service.dart';

/// 広告まわりの初期化とAdGate(app_common_kit)の保持。
///
/// 児童向けアプリのため、常に子供向けタグ・最大レーティングG・非パーソナライズ広告を指定する。
/// 表示ルール(うかラボ共通方針): インタースティシャルは演習セッション終了時のみ
/// (最短3分間隔・1日5回)、バナーはホームのみ。出題中は出さない。
/// 広告非表示プラン加入中は広告SDKを初期化せず何も出さない。
class AdService {
  AdService._();

  static AdGate? _gate;

  /// 初期化に失敗した場合はnull（広告なしで動作を続ける）。
  static AdGate? get gate => _gate;

  /// 本番の広告ユニットID。ビルド時に `--dart-define` で渡す(コミットしない)。
  /// `AD_BANNER_ID` / `AD_INTERSTITIAL_ID` / `AD_REWARDED_ID`(形式 `ca-app-pub-.../...`)。
  /// リワード広告は使っていないので、未指定でよい。
  static const _bannerId = String.fromEnvironment('AD_BANNER_ID');
  static const _interstitialId = String.fromEnvironment('AD_INTERSTITIAL_ID');
  static const _rewardedId = String.fromEnvironment('AD_REWARDED_ID');

  /// 広告ユニットID（デバッグ・profile時はGoogle公式テストID、リリースビルドは渡された本番ID）。
  /// リリースで未指定なら空のIDになり、広告なしで起動する(テストIDのまま出すと AdGate が例外にするため)。
  static AdUnitIds get unitIds => kReleaseMode
      ? const AdUnitIds(banner: _bannerId, interstitial: _interstitialId, rewarded: _rewardedId)
      : const AdUnitIds(
          banner: 'ca-app-pub-3940256099942544/6300978111',
          interstitial: 'ca-app-pub-3940256099942544/1033173712',
          rewarded: 'ca-app-pub-3940256099942544/5224354917',
        );

  /// アプリ起動時に一度だけ呼ぶ。[PurchasesService.initialize] の後に呼ぶこと。
  static Future<void> initialize() async {
    try {
      final ids = unitIds;
      _gate = await AdGate.init(
        // 本番IDが未指定(空)のリリースでは、広告SDKを使わない実装にして、広告を出さない。
        backend: ids.banner.isEmpty && ids.interstitial.isEmpty ? NoAdsBackend() : null,
        config: AdConfig(
          unitIds: ids,
          childDirected: true,
          maxAdContentRating: AdContentRating.g,
          nonPersonalizedAds: true,
        ),
        adsHidden: () => PurchasesService.entitlement?.state.adsHidden ?? false,
      );
    } catch (e) {
      debugPrint('AdService.initialize failed: $e');
    }
  }
}
