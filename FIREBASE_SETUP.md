# Firebase セットアップガイド

このドキュメントでは、うかラボ 漢字検定 アプリの Firebase 設定方法を説明します。

## 前提条件

- Google アカウント（プロジェクト管理用）
- Firebase Console へのアクセス

## ステップ 1: Firebase プロジェクト作成

### 1.1 Firebase Console にアクセス

https://console.firebase.google.com にアクセス

### 1.2 新規プロジェクト作成

1. **「プロジェクトを作成」** をクリック
2. **プロジェクト名**: `kanken-app`（または任意の名前）
3. **Analytics を有効化**: チェック
4. **作成** をクリック

### 1.3 待機

プロジェクト作成完了まで約 1-2 分待機

---

## ステップ 2: プラットフォーム登録

### 2.1 Android アプリ登録

1. Firebase Console でプロジェクト選択
2. 左メニュー → **「プロジェクト設定」** → **「アプリを追加」**
3. **Android** を選択
4. パッケージ名: `com.example.kanken`
5. 署名用デバッグ SHA-1:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   # または
   keytool -list -v -keystore ~/kanken_key.jks
   ```
   出力から **SHA-1** をコピー
6. アプリ登録
7. **google-services.json** をダウンロード

### 2.2 google-services.json を配置

```bash
# ダウンロードしたファイルを以下に配置
cp ~/Downloads/google-services.json android/app/
```

### 2.3 iOS アプリ登録

1. **「アプリを追加」** → **iOS** 選択
2. バンドル ID: `com.example.kanken`
3. アプリニックネーム: `Kanken (iOS)`
4. 登録
5. **GoogleService-Info.plist** をダウンロード
6. Xcode で配置:
   ```bash
   cp ~/Downloads/GoogleService-Info.plist ios/Runner/
   ```

---

## ステップ 3: Firebase 機能の設定

### 3.1 Authentication（認証）

1. Firebase Console → **Authentication**
2. **「Sign-in method」** タブ
3. プロバイダ有効化:
   - ✅ **Email/Password**
   - ✅ **Anonymous**（オプション）
   - ✅ **Google**（オプション）

### 3.2 Firestore Database（データベース）

1. Firebase Console → **Firestore Database**
2. **「データベースを作成」**
3. **ロケーション**: `asia-northeast1`（東京）
4. **セキュリティルール**: 以下を設定

```firestore
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーデータ: 本人のみ読み書き可能
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }

    // 問題データ: 誰でも読み取り可能（作成/編集は管理者のみ）
    match /kanji_questions/{document=**} {
      allow read: if true;
      allow write: if false;
    }

    // 回答ログ: 本人のみ読み書き可能
    match /user_answer_logs/{document=**} {
      allow read, write: if request.auth.uid == resource.data.uid;
      allow create: if request.auth.uid == request.resource.data.uid;
    }

    // 苦手漢字: 本人のみ
    match /weak_kanji_lists/{document=**} {
      allow read, write: if request.auth.uid == resource.data.uid;
      allow create: if request.auth.uid == request.resource.data.uid;
    }

    // 模擬試験結果: 本人のみ
    match /mock_exam_results/{document=**} {
      allow read: if request.auth.uid == resource.data.uid;
      allow write: if false;
      allow create: if request.auth.uid == request.resource.data.uid;
    }

    // コレクションバッジ: 本人のみ
    match /collection_badges/{document=**} {
      allow read: if request.auth.uid == resource.data.uid;
      allow write: if false;
      allow create: if request.auth.uid == request.resource.data.uid;
    }

    // 保護者アカウント: 本人のみ
    match /parent_accounts/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
  }
}
```

### 3.3 Cloud Storage（ファイル保存）

1. Firebase Console → **Storage**
2. **「バケットを作成」**
3. ロケーション: `asia-northeast1`
4. セキュリティルール:

```storage
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    match /user_badges/{uid}/{allPaths=**} {
      allow read, write: if request.auth.uid == uid;
    }
  }
}
```

### 3.4 Analytics（分析）

1. Firebase Console → **Analytics**
2. 自動的に有効化
3. カスタムイベント:
   - `aha_moment_reached`
   - `mock_exam_completed`
   - `weak_kanji_practiced`
   - `badge_unlocked`

### 3.5 Crashlytics（エラー報告）

1. Firebase Console → **Crashlytics**
2. 自動的に有効化

### 3.6 Remote Config（リモート設定）

1. Firebase Console → **Remote Config**
2. パラメータ作成:

| キー | 型 | デフォルト値 |
|------|-----|-----------|
| `mock_exam_time_limit` | Number | `600` |
| `mock_exam_pass_score` | Number | `80` |
| `feature_flag_parent_dashboard` | Boolean | `true` |
| `feature_flag_weak_kanji_mode` | Boolean | `true` |

---

## ステップ 4: Credentials を設定

### 4.1 firebase_options.dart を更新

1. Firebase Console → **プロジェクト設定**
2. 各プラットフォームの設定情報をコピー:
   - API Key
   - App ID
   - Project ID
   - など

3. `lib/config/firebase_options.dart` を編集:

```dart
// iOS Configuration
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY_HERE',  // ← Firebase Console からコピー
  appId: 'YOUR_IOS_APP_ID_HERE',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID_HERE',
  projectId: 'YOUR_PROJECT_ID_HERE',
  authDomain: 'YOUR_PROJECT_ID_HERE.firebaseapp.com',
  storageBucket: 'YOUR_PROJECT_ID_HERE.appspot.com',
  iosBundleId: 'com.example.kanken',
);
```

---

## ステップ 5: main.dart 初期化

アプリ起動時に Firebase を初期化:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'lib/config/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

---

## Firestore コレクション初期化（オプション）

### サンプルデータインポート

```bash
# CSV から Firestore にインポート（Firebase CLI が必要）
firebase firestore:import export_data/kanji_questions.json
```

### 手動作成例

```dart
final firestore = FirebaseFirestore.instance;

// 問題データ追加
await firestore.collection('kanji_questions').add({
  'level': 'LEVEL_10',
  'kanji': '水',
  'questionType': 'multipleChoice',
  'choices': ['水', '火', '木', '土'],
  'correctAnswer': '水',
  'version': 1,
});
```

---

## トラブルシューティング

### エラー: "Failed to initialize Firebase"

✅ 解決策:
- `google-services.json` が `android/app/` にあるか確認
- `GoogleService-Info.plist` が `ios/Runner/` にあるか確認
- パッケージ名が Firebase Console と一致しているか確認

### エラー: "Permission denied" (Firestore)

✅ 解決策:
- Firebase Console でセキュリティルールを確認
- ユーザーが認証されているか確認
- Firestore ルールをテストモード（すべてアクセス可能）に変更してテスト

### エラー: "Invalid API key"

✅ 解決策:
- Firebase Console から正しい API キーをコピー
- `firebase_options.dart` に正確にペースト

---

## セキュリティベストプラクティス

1. **Credentials を Git に commit しない**
   ```bash
   echo "lib/config/firebase_options.dart" >> .gitignore
   ```

2. **本番環境でセキュリティルールを厳密に**
   - テストモードは開発のみ
   - 本番環境では必ずセキュリティルール設定

3. **API キーを制限**
   - Firebase Console → プロジェクト設定 → API キー制限

4. **Google Cloud Console で監視**
   - 定期的なアクセスログ確認

---

## 参考リンク

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Docs](https://firebase.flutter.dev/)
- [Firestore セキュリティルール](https://firebase.google.com/docs/firestore/security/overview)

---

**次のステップ**: ローカル環境で `flutter run` を実行して Firebase が正常に初期化されるか確認
