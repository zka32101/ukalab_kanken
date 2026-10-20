# うかラボ 漢字検定 UI統一の設計書

- 対象: 本リポジトリ（アプリ名「うかラボ 漢字検定」。applicationId `com.yourwish.ukarulab.kanji`）
- 種別: 設計書のみ。この PR ではコードを変更しない。
- 調査時点: main（`91f6bb0`）、`pubspec.yaml` の `ukalab_core` は `v0.78.0`、`app_common_kit` は `v3.11.0`。
- 表記: 非公式アプリであることの表記（日本漢字能力検定協会とは無関係である旨）は現状どおり維持する。UI統一で文言を変えない。

## 0. オーナー決定（記録）

| 記号 | 決定 |
|---|---|
| A | 色・書体・下部5タブの Shell・ホームの作り直しを、すべて他のうかラボアプリに揃える |
| B | 他アプリ（ukalab_it_passport 等）のホーム／記録／設定のすべての要素を基準にする |
| C | 漢検固有機能（フレンド・ランキング・バトル・デイリーチャレンジ・保護者ダッシュボード・手書き練習・書き順など）はホームに置く |
| D | 「準備中」項目の整備は保留。**今回のスコープ外** |
| E | 書体は同梱の BIZ UDPゴシックに揃える |
| F | 課金・広告の経路を共通基盤の標準（`entitlementServiceProvider` / `adGateProvider` の override）に統一する |

### 変えてはならない制約

- 児童向け広告設定: `childDirected: true`・最大コンテンツ評価 G・非パーソナライズ広告（`lib/services/ad_service.dart`）
- 保護者ゲート（購入前・保護者向け画面）
- applicationId `com.yourwish.ukarulab.kanji`
- SharedPreferences の名前空間・キー（`kanken` 系。`main.dart` の各ストアが使用）
- 課金の権利ID `noads` / `premium`（商品 `kanken_noads` / `kanken_premium`）
- Firestore のコレクション名・セキュリティルール（`firestore.rules`）

## 1. 現状の構成（実コードより）

### 1.1 起動と画面遷移

`main.dart` は初期化中に起動画面を出し、Firebase → 購入 → 広告 → 文字サイズ → コイン／衣装／学習メモ／デイリー目標／リマインダーの順に初期化して、`ProviderContainer` を作り `MaterialApp.router`（`appRouter`、`lib/router/app_router.dart`）で起動する。ルート `/` は `AuthGateScreen`（未ログイン → ログイン選択、初回 → ニックネーム設定、それ以外 → `HomeScreen`）。

### 1.2 go_router の画面一覧（ルート `/` ＋ 子30画面。すべて `context.push` で積む）

| 区分 | パス | 画面 |
|---|---|---|
| 学習 | `/spaced-repetition-review` | 復習（間隔反復） |
| 学習 | `/stroke-order` | 書き順 |
| 学習 | `/handwriting` | 手書き練習 |
| 学習 | `/weak-kanji` | 苦手漢字モード |
| 学習 | `/readings` | 読み物（解説） |
| 学習 | `/glossary` | 用語集 |
| 学習 | `/study-notes` | 学習メモ／間違いノート |
| 模擬 | `/mock-exam-modes` | 模擬試験モード選択 |
| 模擬 | `/exam-result` | 模擬試験の結果 |
| 模擬 | `/exam-history` | 模擬試験の履歴 |
| 記録 | `/progress` | 進捗ダッシュボード |
| 記録 | `/analytics` | 分析ダッシュボード |
| 記録 | `/weak-areas` | 苦手分析 |
| 記録 | `/learning-plan` | 学習計画 |
| 記録 | `/learning-goals` | 学習目標 |
| 記録 | `/collection-badge` | バッジ |
| ソーシャル | `/friends` | フレンド |
| ソーシャル | `/friend-challenges` | チャレンジ |
| ソーシャル | `/ranking` / `/global-ranking` / `/leaderboard` | ランキング各種 |
| ソーシャル | `/battle-rooms` / `/battle/:roomId` / `/battle-result` | バトル |
| 固有 | `/daily-challenge` | デイリーチャレンジ |
| 固有 | `/events` | イベント |
| 固有 | `/parent-dashboard` | 保護者ダッシュボード |
| 共通 | `/notifications` | 通知センター |
| 共通 | `/settings` | 設定 |
| 共通 | `/paywall` | プラン（課金） |

補足: 演習画面 `PracticeScreen` は `home_screen.dart` 内のクラスで、ルート登録はなくホームから直接遷移する。画面クラスは `lib/screens/`（35ファイル）と `lib/views/`（ホーム・手書き・苦手漢字・バッジ・core 連携の入口）に分かれている。

### 1.3 HomeScreen（`lib/views/home_screen.dart`、1306行）

| 位置 | 内容 |
|---|---|
| AppBar | 「うかラボ 漢字検定」＋ `CertPropBadge` |
| bottomNavigationBar | `BannerAdWidget`（**広告はホームだけ**。`BannerPlacement.home`、`hasAdsRemoved` で非表示） |
| 最上部 | `OshiCard`、`OshiMessageEntry` |
| グループ「今日やること」 | 演習を始める／模擬試験モード（主ボタン）、復習（間隔反復）、漢字の学習、書き順 など |
| グループ「記録」 | 進捗カード、`StreakWidget`、苦手分析、学習計画、学習目標 |
| グループ「試験に向けて」 | `ExamPrepEntryCard`、`OshiReadinessCard` |
| グループ「道具」 | 読み物、用語集、学習メモ、間違いノート |
| グループ「ソーシャル」 | フレンド、チャレンジ、ランキング、スコアボード（＋ランキング／フレンドのプレビュー） |
| グループ「設定・その他」 | バッジ、設定、プラン |
| 他 | 級選択グリッド（`_buildLevelGrid`。12級。上位級で未購入ならペイウォールへ）、レベル進捗 |

### 1.4 SettingsScreen（`lib/screens/settings_screen.dart`、665行）

見出し順: プロフィール／学習（出題除外・手書き判定）／表示／ながら学習／リマインダー／試験に向けて／データの引き継ぎ／データの管理／公開設定（ランキング参加）／サポート（ご意見・不具合報告）／相互紹介／このアプリについて／出典・ライセンス（EDRDG）。バージョン表示・CSV書出し・購入導線・特典説明カードは未整備。

### 1.5 記録系画面

`ProgressDashboardScreen`・`AnalyticsDashboardScreen`・`WeakAreaScreen`・`LearningPlanScreen`・`LearningGoalsScreen`・`CollectionBadgeScreen`・`ExamHistoryScreen`。入口は現状すべてホームのカードから。

### 1.6 課金・広告の現状経路

- 課金: `PurchasesService`（static）が `RevenueCatEntitlementService` を保持し、`hasAdsRemovedProvider`（`purchases_provider.dart`）が `adsHidden` を流す。ペイウォールは `PaywallScreen`。
- 広告: `AdService.initialize()` が `AdGate.init(...)` を行い、`AdService.gate` を static で参照。バナーは `BannerAdWidget` 経由でホームのみ。
- どちらも Riverpod の標準 provider を override せず、static 参照が混在している（目標は §5）。

## 2. 目標構成と Shell 方式の比較

### 2.1 目標

`UkalabShell`（ukalab_core）の下部5タブ: **ホーム／解く／模擬／記録／設定**。約30画面は従来どおり go_router の `push` で開く。

### 2.2 2案の比較

| 観点 | 案1: `MaterialApp.home` に Shell ＋ `Navigator.push` | 案2: `StatefulShellRoute`（go_router） |
|---|---|---|
| 構成 | `MaterialApp.router` をやめ、`home` に認証ゲート→Shell。画面は `Navigator.push` | go_router のまま 5 ブランチを定義 |
| 他アプリとの一致 | 高い（他アプリと同形になる見込み。要確認） | 低い（漢検だけ別構造） |
| 既存 `context.push('/…')` 約30箇所 | 書き換え必要（`goX()` 拡張を `Navigator.push` 化） | そのまま使える |
| ディープリンク／パス指定 | 失う（現状も実利用は未確認） | 維持 |
| タブ状態保持 | Shell 側（`IndexedStack`）で保持 | ブランチごとに保持 |
| 下部タブの出し分け | push 画面は Shell の外＝タブ非表示（他アプリと同じ） | `parentNavigatorKey` で制御が必要 |
| 認証ゲート | `AuthGateScreen` がそのまま Shell を返せる | `redirect` と状態連携が必要 |
| 変更量 | 中（ルーティング層を置換） | 中（ルート再設計）。ただし core の Shell を包む追加実装が要る |
| リスク | push 化の取りこぼし、戻る挙動の差 | core 標準から逸脱し、追従コストが増える |

### 2.3 推奨: 案1（`MaterialApp.home` に Shell ＋ `Navigator.push`）

理由: (1) オーナー決定 A・B「他アプリに揃える」と一致。(2) `AuthGateScreen` が分岐を既に担っており、`HomeScreen` の代わりに Shell を返すだけで済む。(3) 公開ディープリンクの用途が現状見当たらない。

ただし移行の安全のため、**`appRouter` の定義は段階2では残し**、`goX()` 拡張の中身だけを段階的に `Navigator.push` へ寄せる（拡張の呼び出し側は変更不要）。ルート `/:roomId` を含むバトル系は引数付きで確認する。全画面の移行確認後に `appRouter` を削除する（最終段階）。他アプリの実装形を実コードで再確認してから確定する（未決 §7-1）。

### 2.4 バナー広告の位置

現状はホームの `bottomNavigationBar` のみ。Shell 導入後は、タブ共通の下部（タブバーの上）に1つだけ置く案を推奨し、以下を守る。

- 児童向け設定（§0）は不変。`adGateProvider` 経由で `adsHidden` 時は非表示。
- 解答中・模擬試験中など集中画面（push 画面）には出さない（現状と同じ。誤タップ防止）。
- 配置の最終決定はオーナー判断（未決 §7-2）。

## 3. タブへの画面割当とホーム新構成

### 3.1 割当表

| タブ | 画面 |
|---|---|
| ホーム | 級選択グリッド、漢検固有機能（デイリーチャレンジ、フレンド、チャレンジ、ランキング各種、バトル、保護者ダッシュボード、手書き練習、書き順、イベント、バッジ、推し） |
| 解く | 演習、復習（間隔反復）、苦手漢字モード、漢字の学習、読み物（解説）、用語集、学習メモ／間違いノート |
| 模擬 | 模擬試験モード選択、結果、履歴（`/exam-history`） |
| 記録 | 進捗、分析、苦手分析、学習計画、学習目標 |
| 設定 | 設定（§4）、プラン（課金）、通知センター（入口） |

注: 決定 C により「手書き練習・書き順」はホームに置く（学習系だが固有機能として扱う）。バッジの置き場所は未決（ホーム or 記録。§7-3）。

### 3.2 ホームの新構成

| 現状の要素 | 新構成での扱い |
|---|---|
| 今日やること（演習／模擬の主ボタン） | core の `DailyMissionCard` ＋ 「解く」「模擬」タブへの導線に置換 |
| 学習リマインダー関連 | core の `StudyReminderCard` に置換（`reminderOverrides('kanken')` を継続） |
| `OshiReadinessCard`／`ExamPrepEntryCard` | core の `ReadinessProgressCard` 等に置換できるかを確認し、できなければ残す |
| 進捗カード・`StreakWidget` | 「記録」タブへ移動、ホームには要約のみ |
| 級選択グリッド（12級・購入導線つき） | **残す**（漢検固有） |
| 漢検固有機能のカード群 | **残す**（決定 C） |
| 道具（読み物・用語集・メモ） | 「解く」タブへ移動 |
| 設定・その他（設定・プラン） | 設定タブへ移動 |

置換の可否は core の実装（v0.78.0 時点で公開されている部品）を確認して確定する。1306行の `home_screen.dart` は、置換と移動後に大幅に縮小する見込み。

## 4. 設定の見出し構成（it_passport に揃える案）

| 順 | 見出し | 内容 | 備考 |
|---|---|---|---|
| 1 | プロフィール | 現状の `_ProfileManagementSection` | 維持 |
| 2 | プラン | 購入導線＋ `PremiumBenefitsCard` ほか特典説明 | 新規。保護者ゲート必須 |
| 3 | 学習 | 出題除外、手書き判定、ながら学習 | 現状を統合 |
| 4 | 表示 | 文字の大きさ、テーマ | 維持 |
| 5 | リマインダー | `ReminderSettingsSection` | 維持 |
| 6 | データ | 引き継ぎ、データ管理、**CSV書出し** | CSV は core の `shareCsv` |
| 7 | 公開設定 | ランキング参加 | §6.3 の確認項目に従う |
| 8 | サポート | フィードバック、相互紹介 | 維持 |
| 9 | このアプリについて | **バージョン表示**、非公式の旨 | バージョンは新規 |
| 10 | 出典・ライセンス | EDRDG ほか | 維持 |

**CSV書出し（`shareCsv`）は core v0.79.0 で追加される予定の機能だが、v0.79.0 はまだタグが作成されていない。** タグ作成後に `pubspec.yaml` の `ukalab_core` の ref を更新して使う。それまでは CSV 書出しの項目を実装しない（枠だけ作らない）。見出し構成は it_passport の実コードを再確認して確定する（未決 §7-1）。

## 5. 課金・広告の標準化手順と実機検証

### 5.1 手順

1. `PurchasesService` が生成する `RevenueCatEntitlementService` を、`entitlementServiceProvider` の override として `ProviderContainer` に登録する（`main.dart`）。
2. `AdService` が生成する `AdGate` を、`adGateProvider` の override として登録する。`adsHidden` は entitlement 状態から導く。
3. `hasAdsRemovedProvider`・`BannerAdWidget`・`PaywallScreen`・上位級の購入判定を、static 参照から provider 参照へ置き換える。
4. 権利ID（`noads` / `premium`）、商品ID、`AdConfig`（`childDirected: true`・G・非パーソナライズ）は**変更しない**。単体テスト（`ad_service_ids_test.dart` など）で固定する。
5. 置換が済んだら `PurchasesService` / `AdService` の static 公開面を縮小する。

### 5.2 実機検証項目

| # | 項目 | 期待 |
|---|---|---|
| 1 | 購入（`kanken_noads`）→ 広告消去 | 購入直後にバナーが消え、再起動後も消えたまま |
| 2 | 購入（`kanken_premium`）→ 機能解放 | 上位級・プレミアム機能が解放される |
| 3 | 復元 | 再インストール後、復元で権利が戻る |
| 4 | 保護者ゲート | 購入前・復元前に必ず表示される。突破しないと購入画面に進めない |
| 5 | 広告頻度 | バナーはタブ共通の1枠のみ。集中画面には出ない。ダウンタイムなく積み重ならない |
| 6 | 児童向け設定 | 広告リクエストが `childDirected`・G・非パーソナライズで出ている（ログ／テスト ID で確認） |
| 7 | 未購入・オフライン | 起動が止まらず、広告なしで動く |

## 6. 実装の段階（PR分割案）

| 段階 | 内容 | 変更ファイル候補 | テスト観点 | リスク | ロールバック |
|---|---|---|---|---|---|
| 1 | テーマ・書体（BIZ UDPゴシック、色） | `lib/theme/app_theme.dart`、`pubspec.yaml`（fonts）、`assets/fonts/` | `app_theme_test`・`app_theme_color_test`、ダーク時のコントラスト、日本語の字形 | フォント同梱によるサイズ増 | 別PRで進行中。revert 1回 |
| 2 | Shell（5タブ、`AuthGateScreen` から Shell へ） | `lib/screens/auth_gate_screen.dart`、`lib/router/app_router.dart`、新規 Shell 入口 | 戻る操作、タブ状態保持、push 画面の動作（全30画面） | 画面遷移の取りこぼし | Shell を返す1行を `HomeScreen` に戻す |
| 3 | ホーム作り直し | `lib/views/home_screen.dart`、`lib/widgets/home_group.dart` ほか | 級選択、上位級のペイウォール導線、固有機能の到達性 | 導線の欠落（固有機能がホームから消える） | ホームを旧版に戻す |
| 4 | 記録・設定 | `lib/screens/settings_screen.dart`、記録系各画面、（CSV は core v0.79.0 タグ後） | 設定項目の保存キー（`kanken` 系）不変、CSV の内容 | SharedPreferences キーの変更による設定消失 | 設定の並べ替え前に戻す |
| 5 | 課金・広告経路 | `lib/main.dart`、`lib/services/purchases_service.dart`、`ad_service.dart`、`lib/providers/purchases_provider.dart`、`lib/widgets/banner_ad_widget.dart` | §5.2 の実機検証、`ad_service_ids_test` | 児童向け広告設定の脱落、権利の取りこぼし | override を外し旧 static 経路へ |

各段階の共通ルール: 1 PR 1 段階、`flutter analyze` と `flutter test` が通ること、実機確認は段階5（と可能なら段階2）で必須。

## 7. オーナーが決めること（未決）

1. 他アプリ（ukalab_it_passport 等）の Shell／ホーム／設定の実コードとの突き合わせ結果（本書は漢検側の実コードのみ確認済み。他アプリ側の細部は未確認）。
2. バナー広告の最終位置（タブ共通の下部 1 枠でよいか）。
3. バッジ画面の置き場所（ホーム or 記録）。
4. 通知センターの入口（設定タブ or ホーム）。
5. `appRouter` を最終的に削除するか、バトル等の一部だけ残すか。
6. 段階の順序（段階5を段階2より前倒しするか）。
7. `ukalab_core` v0.79.0 のタグ作成時期（CSV書出しの着手条件）。
8. 「準備中」項目（決定 D）の整備時期。**今回はスコープ外**。

### 7.1 児童向けオンライン機能の初期非公開（確認項目）

ランキング・フレンド・バトルは児童が使うため、初期状態は非公開とする。以下を実装前に確認する。

- [ ] ランキング参加は初期オフ（現状の「公開設定」を維持）。オンにする際に保護者ゲートを通す。
- [ ] 公開されるのはニックネームと成績のみ。本名・連絡先・位置情報などの個人情報は扱わない。
- [ ] フレンド追加はフレンドID方式のみ。自由記述の送受信（チャット）は設けない。
- [ ] バトルの相手・結果表示に個人を特定できる情報を出さない。
- [ ] Firestore ルール（`firestore.rules`）を UI 統一で変更しない。変更が必要になったら別PRで審査する。
- [ ] ホームに置く（決定 C）場合も、非公開設定のままでは参加画面に入れない／空状態で案内する。
- [ ] 非公式表記（協会とは無関係）を、設定の「このアプリについて」とストア表記で維持する。

## 8. 範囲外

- 「準備中」項目の整備（決定 D）
- 問題データ・出題ロジック・Firestore スキーマの変更
- 実キー、個人名、外部ストレージの URL を本書や PR に含めること（含めない）

## 9. 段階2 実装状況（Shell 導入）

- `MaterialApp.home` に `AuthGateScreen` を置き、認証・ニックネーム設定の後に `KankenShell`（`UkalabShell` の5タブ: ホーム／学ぶ／模擬／記録／設定）を返す。`MaterialApp.router` は使わない。
- タブの中身（段階2）: ホーム＝既存 `HomeScreen`（そのまま）、学ぶ＝`LearnTabScreen`（学習系の入口一覧）、模擬＝既存 `MockExamModesScreen`、記録＝`RecordTabScreen`（進捗・分析・計画・目標・履歴・バッジ）、設定＝既存 `SettingsScreen`。
- バナー広告はタブ共通の下部1枠（`KankenShell`）。ホーム単独の枠は外した。通知センターの入口はホーム右上のアイコン。
- `NavigationExtension` の `goX()` はすべて `Navigator.push`（`MaterialPageRoute`、ルート名は従来のパス）に置き換え済み。`go_router` の直接呼び出し（`context.go/push/pop`）は画面側からなくした。
- `appRouter` の定義は、全画面の確認が済むまで残す（実行時には使われない。`reading_screens_test`・`glossary_test` が参照）。削除は最終段階。
