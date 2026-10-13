import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_common_kit/app_common_kit.dart';
import 'package:cross_promo_kit/cross_promo_kit.dart';
import 'package:ukalab_core/daily_goal.dart' show dailyGoalOverrides;
import 'package:ukalab_core/reminder.dart' show reminderOverrides;
import 'package:ukalab_core/reminder_notification.dart'
    show ReminderNotificationWatcher, reminderNotifierProvider;
import 'package:ukalab_core/ui.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'widgets/startup_splash.dart';
import 'services/ad_service.dart';
import 'services/audioplayers_sound_backend.dart';
import 'services/coin_sync_service.dart';
import 'services/local_reminder_notifier.dart';
import 'services/purchases_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初期化（Firebase・課金・広告・保存データの読み込み）には時間がかかる。その間、
  // 下部に組織ロゴを出した起動画面を先に出す。初期化が終わったら本来の画面に差し替える。
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: kankenStartupSplash()));

  // Firebase初期化
  // google-services.jsonが存在する場合、ネイティブ側(FirebaseInitProvider)が
  // アプリ起動時に自動でデフォルトアプリを初期化する。この時点ではDart側の
  // Firebase.appsキャッシュがネイティブ状態と同期していないため isEmpty
  // チェックだけでは防げず、initializeApp呼び出し自体が
  // 「A Firebase App named "[DEFAULT]" already exists」で失敗する
  // (未捕捉例外のため、リリースビルドではスプラッシュ画面のままフリーズして見える)。
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  // うかラボ内の相互紹介（Remote Config）。Firebase 初期化の後・別の try/catch。
  // 失敗しても起動を止めず、取得完了後に紹介カードが自動で表示される。
  try {
    unawaited(CrossPromoService.init());
  } catch (_) {}

  // サブスクリプション（広告非表示プラン）初期化
  await PurchasesService.initialize();

  // 広告初期化（児童向け設定を含む。権利状態に依存するため購入初期化の後）
  await AdService.initialize();

  // 学習コイン（app_common_kit）。財布はアプリごと。端末内に保存する。
  // コインは学習の成長でのみ獲得する（課金・広告視聴での付与はしない）。
  final coinService = CoinService(
    store: SharedPreferencesCoinStore('kanken'),
    shop: OutfitCatalog.shopItems([UkalabCert.kanjiKentei]),
  );
  await coinService.load();
  // 衣装（着替え・ショップ。合格記念・準備完了の解放もここに保存する）
  final outfitService =
      OutfitService(store: SharedPreferencesOutfitStore('kanken'));
  await outfitService.load();

  // ブックマーク・問題メモ・デイリーミッション・リマインダー設定（端末内に保存）
  final studyNotes = await studyNotesOverrides('kanken');
  final dailyGoal = await dailyGoalOverrides('kanken');
  final reminder = await reminderOverrides('kanken');

  // 全アプリ共通フィードバック機能(app_common_kit)の送信処理を注入
  final container = ProviderContainer(
    overrides: [
      coinServiceProvider.overrideWithValue(coinService),
      outfitServiceProvider.overrideWithValue(outfitService),
      handsFreeStoreProvider.overrideWithValue(SharedPreferencesHandsFreeStore('kanken')),
      // 解答時の効果音と触覚（app_common_kit の AnswerFeedback。音源はこのアプリの assets/sounds/）
      answerFeedbackProvider.overrideWithValue(AnswerFeedback(sound: AudioplayersSoundBackend())),
      ...studyNotes,
      ...dailyGoal,
      ...reminder,
      // 端末の通知は Android・iOS だけ。Web は何もしない既定のまま。
      if (!kIsWeb) reminderNotifierProvider.overrideWithValue(LocalReminderNotifier()),
    ],
  );
  // ながら学習モードの設定（片手・読み上げ）を読み込む
  await container.read(handsFreeProvider.notifier).load();
  container.read(feedbackProvider.notifier).setSubmitHandler((report) async {
    await FirebaseFirestore.instance
        .collection('feedback')
        .doc(report.id)
        .set(report.toJson());
  });
  // 学習コインを共通アカウントと同期する（サインイン時・アプリに戻ったとき）
  CoinSyncService(
    container: container,
    userChanges: FirebaseAuth.instance.authStateChanges().map((u) => u?.uid),
  ).start();
  // 未送信分の再送信を試みる(オフライン等で失敗した報告のリトライ)
  unawaited(container.read(feedbackProvider.notifier).retryPendingReports());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'うかラボ漢字検定',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      builder: (context, child) =>
          ReminderNotificationWatcher(child: child ?? const SizedBox.shrink()),
    );
  }
}
