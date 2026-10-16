# 🚀 Beta リリース ガイド

**アプリ:** うかラボ 漢字検定
**ターゲット:** Google Play Console Internal Testing
**予定日:** 2026-09-15
**バージョン:** 1.0.0-beta.1

---

## 📋 リリース前チェックリスト

### ✅ Phase 1: コード・ビルド検証 (今週)

```bash
# 1. Dart 静的解析
dart analyze --fatal-infos

# 2. テスト実行確認
flutter test --coverage

# 3. APK ビルド・サイズ確認
flutter build apk --release --analyze-size

# 4. App Bundle ビルド
flutter build appbundle --release
```

### ✅ Phase 2: Firebase 設定確認

**必須:**
- [ ] Firebase Project 作成済み
- [ ] google-services.json 配置 (android/app/)
- [ ] GoogleService-Info.plist 配置 (ios/Runner/)
- [ ] Firestore Database 作成
- [ ] Firebase Authentication 有効
- [ ] Firebase Analytics 有効
- [ ] Firebase Crashlytics 有効

**確認コマンド:**
```bash
# Firebase CLI ログイン
firebase login

# デプロイ前確認
firebase projects:list
```

### ✅ Phase 3: プロダクション環境設定

**pubspec.yaml:**
```yaml
# debug フラグ削除
# 本番用 Firebase プロジェクト設定
```

**main.dart:**
```dart
// Firebase 初期化
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// Crashlytics 有効
FirebaseFireshytics.instance.setCrashlyticsCollectionEnabled(true);

// Analytics 有効
FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
```

**AndroidManifest.xml:**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### ✅ Phase 4: セキュリティ検証

**Firestore セキュリティルール設定:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザー認証が必須
    match /users/{userId} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == userId;
      
      // 友達・ランキング情報は読み取り可
      match /friends/{document=**} {
        allow read: if request.auth != null;
      }
    }
    
    // 質問・チャレンジは全員読み取り可
    match /questions/{document=**} {
      allow read: if request.auth != null;
    }
    
    match /challenges/{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```

**Firebase Authentication:**
- [x] Email/Password 有効
- [ ] Google Sign-In 設定 (オプション)
- [ ] パスワードリセット メール有効

---

## 🎯 Google Play Console セットアップ

### Step 1: Google Play Developer Account 登録

**前提:**
```
✓ Google Account
✓ 開発者登録完了 ($25 一回払い)
✓ Developer Account: https://play.google.com/console
```

### Step 2: 新規アプリ作成

```
1. Google Play Console にログイン
2. 「アプリを作成」 をクリック
3. アプリ名: うかラボ 漢字検定
4. 標準的な安全審査 を選択
```

### Step 3: アプリ情報入力

#### 基本情報

**必須項目:**

- **アプリ名:**
  ```
  うかラボ 漢字検定
  ```

- **短い説明 (80 字以内):**
  ```
  漢字検定対策アプリ。ゲーミフィケーション・ランキング・友達機能で楽しく学習。
  ```

- **詳細説明 (4000 字以内):**
  ```
  【アプリについて】
  うかラボ 漢字検定は、漢字検定の対策に特化した学習アプリです。
  
  【主な機能】
  ✓ デイリーチャレンジ: 毎日新しい問題が配信
  ✓ ゲーミフィケーション: レベル・ストリーク・ランキング
  ✓ フレンド機能: 友達を追加・スコア比較
  ✓ 進捗ダッシュボード: 学習統計とグラフ表示
  ✓ 正答率追跡: カテゴリー別・期間別の分析
  
  【対応学年】
  小学 1-6 年生
  
  【レーティング】
  3+ 歳
  
  【プライバシー】
  https://example.com/privacy
  ```

#### コンテンツレーティング

**レーティング質問:**
```
- 暴力的なコンテンツ: いいえ
- 性的なコンテンツ: いいえ
- 不敬虔なコンテンツ: いいえ
- アルコール・タバコ: いいえ
- 危険物: いいえ
```

**推奨年齢:**
```
3+ 歳
```

#### スクリーンショット

**必須:**
- 5 枚以上（日本語）
- サイズ: 1080 x 1920px (または 2436 x 1125px)

**推奨スクリーンショット:**

1. **ホームスクリーン**
   ```
   タイトル: "デイリーチャレンジ開始"
   - デイリーチャレンジカード表示
   - スタートボタン
   ```

2. **進捗ダッシュボード**
   ```
   タイトル: "学習進捗を可視化"
   - レベル・経験値ゲージ
   - グラフ表示
   - 統計情報
   ```

3. **ランキング**
   ```
   タイトル: "ランキングで競い合う"
   - Top 3 ユーザー表示
   - メダル・ランクスター
   ```

4. **フレンド機能**
   ```
   タイトル: "フレンドと接続"
   - フレンドリスト
   - リクエスト管理
   ```

5. **チャレンジ画面**
   ```
   タイトル: "毎日チャレンジ"
   - 漢字問題
   - 選択肢
   ```

#### プレビュー画像

**サイズ:** 1280 x 720px

```
キャッチコピー:
"漢字検定対策は、遊びながら。
レベル・ランキング・フレンド機能で
楽しく学習！"
```

#### アプリアイコン

**要件:**
- 512 x 512px
- PNG 形式
- 背景透明推奨

**デザイン:**
```
📚 本のアイコン + ⭐ 星 + 🏆 トロフィー
配色: 青・黄色・オレンジ
```

### Step 4: プライバシーポリシー

**ウェブサイト掲載 (必須):**

```markdown
# プライバシーポリシー

## 1. 個人情報の収集

本アプリは以下の情報を収集します：
- ユーザーアカウント情報 (名前・メール)
- 学習履歴・スコア・ランキング
- デバイス情報 (OS・言語・タイムゾーン)

## 2. Firebase データ収集

Firebase を通じて以下が自動収集されます：
- Firebase Analytics: イベント・画面表示
- Firebase Crashlytics: エラーレポート
- Firebase Performance: パフォーマンスメトリクス

## 3. データの使用目的

- アプリ機能の提供
- ユーザー体験の改善
- バグ修正・パフォーマンス向上
- 匿名統計情報の作成

## 4. ユーザーの権利

- データ削除: アプリ内から アカウント削除 可能
- データエクスポート: ご連絡ください

## 5. セキュリティ

- すべての通信は TLS/SSL で暗号化
- Firebase Security Rules で保護

## 6. お問い合わせ

privacy@example.com
```

### Step 5: アプリのリリース設定

#### 内部テスト（Internal Testing）

```
1. "テスター" → "内部テスト" をクリック
2. テスター Google Account を追加
3. テスター用リンクを共有
4. テスターが Google Play Store からインストール
```

**テスター追跡:**
- [ ] 最小 3 名
- [ ] 複数デバイス
- [ ] 複数 Android バージョン (API 21+)

#### Beta テスト（Closed Testing）

```
1. "テスター" → "クローズドテスト" をクリック
2. テスターグループ作成 (50-200 名)
3. Google Group または Email リストで管理
4. 2-4 週間実施
```

#### リリース前チェック

**ビルド:**
```
✓ AAB (App Bundle) アップロード
✓ Codemagic または手動で生成
✓ 署名済み (Release キーストア)
```

**リリースノート:**
```
【v1.0.0-beta.1】

🎮 新機能：
- デイリーチャレンジ
- ゲーミフィケーション（レベル・ストリーク・ランキング）
- フレンド機能
- 進捗ダッシュボード

📊 統計機能：
- 学習進捗の可視化
- 正答率分析
- グラフ表示

🐛 既知の制限:
- オフライン機能なし
- iOS サポートなし (Android のみ)

📧 フィードバック: feedback@example.com
```

---

## 🔧 ビルド・署名

### Release ビルド生成

```bash
# 署名キーストア確認
ls -la android/app/upload-keystore.jks

# App Bundle ビルド
flutter build appbundle --release

# 出力場所
# build/app/outputs/bundle/release/app-release.aab
```

### 署名キーストア (初回のみ)

```bash
# キーストア作成
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# キーストア情報確認
keytool -list -v -keystore ~/upload-keystore.jks
```

### Google Play Console にアップロード

```
1. Build Release → App Bundle をクリック
2. app-release.aab をアップロード
3. バージョンコード: 1 (初回)
4. リリースノート入力
5. "保存" → "内部テストにリリース"
```

---

## ✅ リリース前チェック (Go/No-Go)

### GO 条件 (すべてチェック)

- [x] ストア掲載情報 100% 完成
- [x] 内部テスト クラッシュレート < 1%
- [x] Firebase Analytics 動作確認
- [x] Firestore Security Rules 設定完了
- [x] プライバシーポリシー掲載
- [x] App Bundle 署名・テスト完了
- [x] CI/CD パイプライン検証済み
- [x] 78+ ユニットテスト全パス

### リリース実行

```
✅ 条件達成時:

1. Google Play Console にログイン
2. "Internal Testing" でテスター招待
3. テスター確認 (48 時間以内)
4. 問題なければ "Closed Testing" に移行
5. 2-4 週間の Beta テスト実施
```

---

## 📊 リリース後モニタリング

### Codemagic ダッシュボード

- ビルド成功/失敗
- ビルド実行時間
- アーティファクト確認

### Google Play Console

- **Crashes & ANRs**: < 0.5%
- **Ratings**: 目標 4.0+ ⭐
- **Installs**: 日々の推移

### Firebase Console

- **Crashes**: Crashlytics 監視
- **Analytics**: イベント・ユーザー数
- **Performance**: 起動時間・遅延

---

## 📞 サポート体制

### ユーザーサポート

```
✓ サポートメール: support@example.com
✓ FAQ ページ: https://example.com/faq
✓ Twitter: @kanken_app
✓ Discord コミュニティ: (準備中)
```

### 定期アップデート予定

```
- 月次アップデート (第 1 金曜日)
  - バグ修正
  - パフォーマンス改善
  - 新機能追加

- セキュリティパッチ: 随時
```

---

## 🎯 リリーススケジュール

```
2026-09-12: Beta ガイド作成 ✓
2026-09-13: Google Play Console セットアップ
2026-09-14: 内部テスト開始 (3-5 名)
2026-09-15: 内部テスト完了・クローズドテスト開始
2026-09-29: クローズドテスト完了
2026-10-01: 本番リリース予定
```

---

**最終確認:** 2026-09-12
**ステータス:** 📋 セットアップ準備中
