# ✅ プロダクション環境チェックリスト

## 📱 アプリ品質チェック

### コード品質
- [ ] Dart Analyzer エラー 0
  ```bash
  dart analyze --fatal-infos
  ```
- [ ] 未使用インポート削除
- [ ] 型安全性確認（null safety）

### パフォーマンス
- [ ] APK サイズ確認 (< 50MB 推奨)
  ```bash
  flutter build apk --release --analyze-size
  ```
- [ ] 起動時間測定
- [ ] メモリ使用量テスト
- [ ] クラッシュレート < 1%

### セキュリティ
- [ ] Firebase Authentication 設定
  - [ ] Email/Password サインイン
  - [ ] Google サインイン設定
  - [ ] Session timeout 設定

- [ ] Firebase Security Rules 設定
  ```javascript
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
  ```

- [ ] API Key セキュリティ
  - [ ] google-services.json を git に commit しない
  - [ ] BuildConfig 経由でアクセス

- [ ] データ保護
  - [ ] 通信 TLS/SSL 必須
  - [ ] ローカル DB 暗号化（Hive/Sqflite）

### Android 標準要件

- [ ] **64-bit サポート**
  ```gradle
  ndk {
    abiFilters 'arm64-v8a'
  }
  ```

- [ ] **最小 SDK バージョン**
  - `minSdkVersion 21` (Android 5.0)

- [ ] **ターゲット SDK**
  - `targetSdkVersion 34` (最新)

- [ ] **Manifest 権限**
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
  ```

### UI/UX

- [ ] ダークモード対応
- [ ] マルチ言語対応
  ```dart
  // intl パッケージで多言語対応済み確認
  ```
- [ ] アクセシビリティ
  - [ ] 最小タップサイズ 48dp
  - [ ] セマンティックラベル設定
- [ ] 異なる画面サイズ対応
  - [ ] 4.5" (小)
  - [ ] 5.5" (中)
  - [ ] 7.0" (タブレット)

---

## 🔒 プライバシー・コンプライアンス

### プライバシーポリシー
- [ ] 日本語で記載
- [ ] ウェブサイトに掲載
- [ ] 内容
  - [ ] 個人情報の取り扱い
  - [ ] Firebase Analytics データ収集
  - [ ] 広告表示について
  - [ ] ユーザーの権利

### サードパーティ SDK

- [ ] Firebase - データ収集明記
- [ ] Google Analytics - 個人情報なし確認
- [ ] 広告 SDK - プライバシーポリシーへのリンク

### ユーザーデータ権
- [ ] データ削除機能
  - ローカル DB クリア
  - Firebase user 削除
- [ ] データエクスポート機能（オプション）

---

## 📊 Analytics & Monitoring

### Firebase Analytics 設定
- [ ] Custom Events 定義
  ```dart
  await FirebaseAnalytics.instance.logEvent(
    name: 'kanken_challenge_completed',
    parameters: {
      'level': level,
      'score': score,
    },
  );
  ```

- [ ] User Properties
  ```dart
  await FirebaseAnalytics.instance.setUserProperty(
    name: 'user_level',
    value: userLevel,
  );
  ```

### Firebase Crashlytics
- [ ] エラー報告設定
  ```dart
  FirebaseCrashlytics.instance.recordFlutterFatalError(exception);
  ```
- [ ] Cloud Functions トリガー（重大エラー検出）

### パフォーマンス監視
- [ ] 重要ユーザーフローの測定
  ```dart
  FirebasePerformance.instance.startTrace('lesson_load')
    ..stop();
  ```

---

## 🚀 リリース前テスト

### 内部テスト（1-2週間）
- [ ] チームメンバー 3-5 名でテスト
- [ ] 複数デバイス・OSバージョンで確認
  - [ ] Android 5.0 (API 21)
  - [ ] Android 8.0 (API 26)
  - [ ] Android 12.0+ (API 31+)

### Beta テスト（2-4週間）
- [ ] テスターグループ 50-200 人
- [ ] 各デバイス種別でレポート収集
- [ ] クラッシュ・バグ修正

### 本番リリース前チェック
- [ ] クラッシュレート < 0.5%
- [ ] ANR（Application Not Responding） なし
- [ ] ストア掲載情報完成度 100%
- [ ] レーティング適切（対象年齢に合致）

---

## 📋 ストア掲載情報

### 必須項目

- [ ] **アプリ説明** (80 文字以内 / 4000 文字以内)
  ```
  【非公式】うかラボ 漢字検定。本アプリは日本漢字能力検定の運営団体とは関係のない、独自に制作した非公式の学習アプリです。
  日本語テキスト。効率的な学習。
  ```

- [ ] **スクリーンショット**
  - [ ] 5 枚以上（日本語）
  - [ ] サイズ: 1080x1920px 推奨
  - [ ] テキスト・矢印で機能説明

- [ ] **プレビュー画像**
  - [ ] 1280x720px 以上
  - [ ] キャッチコピー・マーケティング用

- [ ] **アプリアイコン**
  - [ ] 512x512px
  - [ ] PNG形式
  - [ ] 背景透明推奨

### オプション項目

- [ ] 動画（YouTube リンク）
  - [ ] 30 秒以上推奨
  - [ ] 画面録画 + ナレーション

- [ ] 開発者連絡先
  - [ ] Email アドレス
  - [ ] ウェブサイト

- [ ] サポートメール
  - [ ] ユーザーサポート用

---

## 🔄 アップデート戦略

### バージョニング
- `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- 例: `1.0.0+1` → `1.0.1+2` → `1.1.0+3`

### リリーススケジュール
- [ ] 初回リリース: v1.0.0
- [ ] 月次アップデート予定
- [ ] セキュリティ修正: 随時

### リリースノート例
```
[v1.0.1] - 2024年9月11日

🐛 バグ修正:
- ログイン画面の表示エラー修正
- 漢字リストのスクロール改善

✨ 機能改善:
- 学習進捗の保存速度向上
- UI レスポンス改善

🔒 セキュリティ:
- Firebase ルール更新
```

---

## 📞 サポート体制

- [ ] バグレポート受付メール設定
- [ ] FAQ ページ作成
- [ ] Twitter/社交メディア アカウント
- [ ] ユーザーコミュニティ（Discord など）

---

## 最終確認

### GO/NO-GO 判定

**GO 条件 (すべてチェック):**
- [ ] ストア掲載情報 100% 完成
- [ ] 内部テスト クラッシュレート < 1%
- [ ] β版テスト 2週間以上実施
- [ ] プライバシーポリシー掲載
- [ ] Firebase Analytics 動作確認
- [ ] サポートメール設定完了

**→ 本番公開 OK**

**NO-GO 条件 (1つでも該当):**
- [ ] クラッシュレート > 1%
- [ ] ストア掲載情報不足
- [ ] プライバシーポリシーなし
- [ ] テスト期間不足

**→ 改善待機**

---

**チェックリスト作成日:** 2026-09-11  
**次回確認予定:** リリース 1週間前
