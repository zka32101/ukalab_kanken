#!/bin/bash
# うかラボ 漢字検定 - APK ビルドスクリプト
# 使用方法: bash build_apk.sh [debug|release]

set -e

# カラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# デフォルト値
BUILD_TYPE=${1:-release}
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}うかラボ 漢字検定 APK ビルドスクリプト${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# 環境確認
echo -e "${YELLOW}[1/6] 環境確認...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ エラー: Flutter がインストールされていません${NC}"
    echo "https://flutter.dev/docs/get-started/install を参照して Flutter をインストールしてください"
    exit 1
fi

if ! command -v keytool &> /dev/null; then
    echo -e "${RED}❌ エラー: keytool がインストールされていません${NC}"
    echo "Java Development Kit (JDK) をインストールしてください"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -1)
echo -e "${GREEN}✅ Flutter: ${FLUTTER_VERSION}${NC}"

# Keystore 確認
echo ""
echo -e "${YELLOW}[2/6] Keystore 確認...${NC}"

KEYSTORE_PATH=~/kanken_key.jks
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo -e "${RED}❌ Keystore が見つかりません: ${KEYSTORE_PATH}${NC}"
    echo ""
    echo -e "${YELLOW}Keystore を作成しますか？ (y/n)${NC}"
    read -r response
    if [ "$response" = "y" ]; then
        echo "パスワードを入力してください（8文字以上）:"
        read -s PASSWORD
        echo ""
        echo "パスワードを再度入力してください:"
        read -s PASSWORD_CONFIRM

        if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
            echo -e "${RED}❌ パスワードが一致しません${NC}"
            exit 1
        fi

        echo "以下の情報を入力してください:"
        echo "姓名: "
        read -r NAME
        echo "組織名: "
        read -r ORG
        echo "都市: "
        read -r CITY
        echo "都道府県: "
        read -r STATE
        echo "国コード（JP）: "
        read -r COUNTRY

        keytool -genkey -v -keystore "$KEYSTORE_PATH" \
            -keyalg RSA \
            -keysize 2048 \
            -validity 10000 \
            -alias kanken_key \
            -storepass "$PASSWORD" \
            -keypass "$PASSWORD" \
            -dname "CN=$NAME, OU=$ORG, L=$CITY, ST=$STATE, C=$COUNTRY"

        echo -e "${GREEN}✅ Keystore を作成しました${NC}"
    else
        exit 1
    fi
else
    echo -e "${GREEN}✅ Keystore を確認しました${NC}"
fi

# key.properties 確認
echo ""
echo -e "${YELLOW}[3/6] key.properties 確認...${NC}"

PROPERTIES_FILE="$PROJECT_DIR/android/key.properties"
if [ ! -f "$PROPERTIES_FILE" ]; then
    echo -e "${RED}❌ key.properties が見つかりません${NC}"
    echo "以下のコマンドで作成してください:"
    echo ""
    echo "cat > $PROPERTIES_FILE << EOF"
    echo "storePassword=YOUR_PASSWORD"
    echo "keyPassword=YOUR_PASSWORD"
    echo "keyAlias=kanken_key"
    echo "storeFile=$KEYSTORE_PATH"
    echo "EOF"
    echo ""
    exit 1
else
    echo -e "${GREEN}✅ key.properties を確認しました${NC}"
fi

# Firebase オプション確認
echo ""
echo -e "${YELLOW}[4/6] Firebase 設定確認...${NC}"

FIREBASE_OPTIONS="$PROJECT_DIR/lib/config/firebase_options.dart"
if grep -q "YOUR_PROJECT_ID_HERE" "$FIREBASE_OPTIONS"; then
    echo -e "${RED}❌ Firebase 認証情報が設定されていません${NC}"
    echo "firebase_options.dart を編集して、認証情報を記入してください"
    echo ""
    echo "詳細は FIREBASE_SETUP.md を参照してください"
    exit 1
else
    echo -e "${GREEN}✅ Firebase 認証情報を確認しました${NC}"
fi

# Flutter pub get
echo ""
echo -e "${YELLOW}[5/6] 依存関係をダウンロード...${NC}"
cd "$PROJECT_DIR"
flutter pub get

# ビルド実行
echo ""
echo -e "${YELLOW}[6/6] APK をビルド（${BUILD_TYPE} モード）...${NC}"
echo ""

if [ "$BUILD_TYPE" = "debug" ]; then
    flutter build apk --debug
    APK_PATH="$PROJECT_DIR/build/app/outputs/apk/debug/app-debug.apk"
elif [ "$BUILD_TYPE" = "release" ]; then
    flutter build apk --release
    APK_PATH="$PROJECT_DIR/build/app/outputs/apk/release/app-release.apk"
else
    echo -e "${RED}❌ 無効なビルドタイプ: ${BUILD_TYPE}${NC}"
    echo "使用方法: bash build_apk.sh [debug|release]"
    exit 1
fi

# 結果確認
echo ""
echo -e "${BLUE}======================================${NC}"
if [ -f "$APK_PATH" ]; then
    SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo -e "${GREEN}✅ ビルド成功！${NC}"
    echo ""
    echo -e "${GREEN}📦 出力ファイル:${NC}"
    echo "   $APK_PATH"
    echo -e "${GREEN}📊 ファイルサイズ: ${SIZE}${NC}"
    echo ""
    echo -e "${GREEN}📱 実機にインストール:${NC}"
    echo "   adb install -r \"$APK_PATH\""
    echo ""
    echo -e "${GREEN}🚀 Google Play にアップロード:${NC}"
    echo "   Google Play Console で AAB ファイルをアップロード"
    echo ""
else
    echo -e "${RED}❌ ビルド失敗${NC}"
    echo "エラーメッセージを確認してください"
    exit 1
fi

echo -e "${BLUE}======================================${NC}"
