# うかラボ 漢字検定

漢字検定対策アプリ（Flutter/Dart）。小1〜小6対象。

## プロジェクト概要

**Vision:** 「漢検が、しんどい暗記から親子で楽しむ挑戦に変わる社会」

### 差別化要素
- ✨ UI品質（ごほうび演出：紙吹雪、全画面ゴールド、バッジ）
- 💰 収益化: 広告あり＋買い切りで広告非表示（他のうかラボと同じ。方針 D3）。「広告なし」¥480（`kanken_noads`）／準1級・1級も学べる「プレミアム」¥1,500（`kanken_premium`）。価格はストア（Play・RevenueCat）の商品設定が正。
  - 広告: AdMob（バナー・インタースティシャル。児童向け設定・非パーソナライズ。`lib/services/ad_service.dart`）。購入済みは広告SDKを初期化しない。
  - 無料版の制限（方針 D6）: 模擬試験は月1回、「今日の復習」は1日10問まで（案内だけ。間違いノート・演習は無料）。
  - 公開SDKキーと広告ユニットIDは、ビルド時に `--dart-define`（`RC_GOOGLE_KEY` / `AD_BANNER_ID` / `AD_INTERSTITIAL_ID`）で渡す。コミットしない。
- 👨‍👩‍👧 親子軸（保護者ダッシュボード・進捗管理）
- 🤖 AI苦手分析（誤答傾向→苦手集中特訓モード）
- 🎯 模擬試験モード（「あと◯点」可視化→継続動線）

## スタック

- **Language:** Dart 3.x
- **Framework:** Flutter 3.13+
- **State Management:** Riverpod
- **Backend:** Firebase (Firestore/Auth/Analytics/Crashlytics/Remote Config)
- **Monetization:** RevenueCat
- **Animation:** Lottie
- **共通基盤:** petit_core / petit_ui / petit_ai

## ディレクトリ構成

```
lib/
  ├── models/          # User, KanjiQuestion, UserAnswerLog, etc.
  ├── services/        # Firestore, MockExam, AIWeakAnalysis, Handwriting
  ├── viewmodels/      # Riverpod Providers
  ├── views/           # UI Screens
  ├── widgets/         # Custom Widgets
  └── main.dart        # Entry point
```

## 実装順序（推奨）

1. ✅ データモデル（User, KanjiQuestion, etc.）
2. ✅ Service層（FirestoreService, MockExamService, etc.）
3. ✅ ViewModel/Riverpod設定
4. ⏳ **Aha Moment最短動線** ← 次のフォーカス
5. ⏳ 各画面（Home, Practice, MockExam, Collection, ParentDashboard）
6. ⏳ アニメ・効果音・UX演出
7. ⏳ テスト・CI/CD

## Getting Started

### 前提条件
- Flutter 3.13+
- Dart 3.0+
- 環境変数: Firebase APIキー設定（firebase_options.dart）

### セットアップ

```bash
flutter pub get
flutter run
```

## 計測KPI

- `aha_moment_reached`: 初回3問正解達成
- `mock_exam_completed`: 模擬試験完了
- `weak_kanji_practiced`: 苦手集中トレーニング
- `badge_unlocked`: バッジ獲得
- `paywall_converted`: 有料転換

## リリース基準

- Day1リテンション 30%+
- クラッシュフリー 99.5%+
- Aha到達率 60%+

---

詳細は `引き継ぎドキュメント.md` を参照
## アプリ名・表示名

- 表示名: **うかラボ 漢字検定**（Android ランチャーラベルも同じ。9文字で切れないためフル表記を採用）
- 本アプリは日本漢字能力検定の運営団体とは関係のない、独自に制作した非公式の学習アプリです。「漢検」「漢字検定」は各権利者の商標または登録商標です。ストア掲載名には「非公式」を含めるか、説明文の1行目に上記の注意書きを入れてください。
- 変更しないもの: applicationId / Dart パッケージ名 `kanken` / リポジトリ名 / Firebase プロジェクト ID
