# うかラボ 相互紹介（クロスプロモ）

うかラボ8アプリの相互紹介は `cross_promo_kit` を使う。このアプリは `ukalab_core` の薄いラッパー
（`package:ukalab_core/cross_promo.dart`）経由で使っており、独自の実装は持たない。

## このアプリでの使い方

| 項目 | 内容 |
|---|---|
| appId（`currentAppId`） | `com.yourwish.ukarulab.kanji`（`ukalab_core` の `kUkalabAppIds` にある値） |
| 初期化 | `lib/main.dart` で Firebase 初期化の直後に `unawaited(UkalabCrossPromo.init())`。失敗しても例外を投げず、起動を止めない。購入・広告の初期化より前に置いているが、待たない |
| 表示場所 | 設定画面の「サポート」の下（`lib/screens/settings_screen.dart`）。問題中・模擬試験中・復習中には出さない |
| 掲載0件のとき | 何も表示しない |
| 子ども向けの扱い | `isChildDirected: true` と `beforeOpenStore: requireParentalGate`（保護者ゲート）。ストアを開く前にゲートを通す |
| 広告なし購入者 | 相互紹介は広告ではなく自社アプリの案内なので、購入者にも表示する（方針は要確認） |

## Remote Config 側の作業（コードでは変更できない）

掲載するアプリの一覧（各アプリのストアURL・アイコン・カテゴリ `うかラボ` など）は、
Firebase Remote Config で配信する。リポジトリには掲載リストを置いていない。
掲載リストが空のままなら、画面には何も出ない。

- キー名と JSON の形式は **cross_promo_kit のドキュメントを参照**する（ここには推測で書かない）。
- 掲載するカテゴリは `うかラボ`（`kUkalabCrossPromoCategory`）。
- ストアURL・キー・個人情報はリポジトリに書かない。
- 対象の Firebase プロジェクトへの投入は運営の判断で行う。

## テスト

`test/cross_promo_test.dart`: appId が一覧にあること、Firebase 未初期化・掲載0件でも初期化とセクションが
例外なく動き何も表示しないこと、子ども向け設定でゲートが無いと assert になること。
