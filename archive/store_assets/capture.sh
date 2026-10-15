#!/usr/bin/env bash
# =============================================================================
# アプリをビルドして端末にインストール・起動する。
# Android 実機 / iOS シミュレータ を自動判別する。
#
# 画面遷移は手動で行う (integration_test / idb 未導入のため UI 自動操作は不可)。
# 起動後は各画面を開いて ./store_assets/snap.sh <name> でキャプチャする。
#
# 使い方:
#   ./store_assets/capture.sh                 # 自動判別
#   ./store_assets/capture.sh --android       # Android を強制
#   ./store_assets/capture.sh --ios           # iOS シミュレータを強制
#   ./store_assets/capture.sh --skip-build    # ビルド済みを再利用
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

# ---------- adb の場所を解決 (PATH に無い環境に対応) ----------
resolve_adb() {
  if command -v adb >/dev/null 2>&1; then command -v adb; return; fi
  for p in \
    "$HOME/Library/Android/sdk/platform-tools/adb" \
    "${ANDROID_HOME:-}/platform-tools/adb" \
    "${ANDROID_SDK_ROOT:-}/platform-tools/adb" \
    "/opt/homebrew/share/android-commandlinetools/platform-tools/adb" \
    "/usr/local/share/android-sdk/platform-tools/adb"; do
    if [ -n "$p" ] && [ -x "$p" ]; then echo "$p"; return; fi
  done
  echo ""
}
ADB="$(resolve_adb)"

MODE="auto"
SKIP_BUILD=0
SKIP_INSTALL=0
FLAVOR="debug"
for a in "$@"; do
  case "$a" in
    --android) MODE="android" ;;
    --ios)     MODE="ios" ;;
    --skip-build)   SKIP_BUILD=1 ;;
    --skip-install) SKIP_INSTALL=1 ;;
    --release) FLAVOR="release" ;;
    --debug)   FLAVOR="debug" ;;
  esac
done

ANDROID_ID=""
if [ -n "$ADB" ]; then
  ANDROID_ID="$("$ADB" devices 2>/dev/null | awk '/\tdevice$/{print $1; exit}')"
fi

if [ "$MODE" = "auto" ]; then
  if [ -n "$ANDROID_ID" ]; then MODE="android"; else MODE="ios"; fi
fi

# =============================== Android ===============================
if [ "$MODE" = "android" ]; then
  if [ -z "$ADB" ]; then
    echo "✗ adb が見つかりません。"
    echo "  Android SDK の platform-tools を PATH に追加するか ANDROID_HOME を設定してください。"
    exit 1
  fi
  if [ -z "$ANDROID_ID" ]; then
    echo "✗ Android 端末が接続されていません ($ADB devices で確認してください)"
    exit 1
  fi
  echo "▶ Android 実機: $ANDROID_ID"

  PKG="com.walkinggoblins.archive"

  if [ "$SKIP_INSTALL" -eq 1 ]; then
    echo "▶ インストールをスキップし、既存のアプリを起動します"
  else
    # debug 署名を既定にしている理由:
    #   開発中に入れたビルドは debug 鍵で署名されている。release 鍵の APK を
    #   install -r すると INSTALL_FAILED_UPDATE_INCOMPATIBLE になり、解消には
    #   アンインストール = 作品データの全消去が必要になってしまう。
    #   main.dart で debugShowCheckedModeBanner: false にしているため、
    #   debug ビルドでも DEBUG リボンは出ず、撮影上の見た目は release と変わらない。
    if [ "$FLAVOR" = "release" ]; then
      APK="build/app/outputs/flutter-apk/app-release.apk"
    else
      APK="build/app/outputs/flutter-apk/app-debug.apk"
    fi

    if [ "$SKIP_BUILD" -eq 1 ] && [ -f "$APK" ]; then
      echo "▶ 既存 APK を再利用: $APK"
    else
      echo "▶ $FLAVOR APK をビルド (数分かかります)"
      flutter build apk --"$FLAVOR"
    fi

    [ -f "$APK" ] || { echo "✗ APK が見つかりません: $APK"; exit 1; }

    echo "▶ インストール"
    INSTALL_LOG="$("$ADB" -s "$ANDROID_ID" install -r "$APK" 2>&1 || true)"
    echo "$INSTALL_LOG"

    if echo "$INSTALL_LOG" | grep -q 'INSTALL_FAILED_UPDATE_INCOMPATIBLE'; then
      cat <<'EOS'

✗ 署名が一致しないためインストールできませんでした。
  端末のアプリと APK が別の鍵で署名されています。

  対処 (データを失わない順):
    1. 反対の署名でビルドし直す
         ./store_assets/capture.sh --android            # debug 署名 (既定)
         ./store_assets/capture.sh --android --release  # release 署名
    2. 再インストールせず、今入っているアプリをそのまま撮影する
         ./store_assets/capture.sh --android --skip-install

  ※ adb uninstall は作品データを全消去します。
     実データを撮影に使いたい場合は実行しないでください。
EOS
      exit 1
    fi
  fi

  echo "▶ 起動: $PKG"
  "$ADB" -s "$ANDROID_ID" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true

# ================================= iOS =================================
else
  DEVICE="iPhone 17 Pro Max"
  echo "▶ iOS シミュレータ: $DEVICE"
  xcrun simctl boot "$DEVICE" 2>/dev/null || echo "  (既に起動済み)"
  xcrun simctl bootstatus "$DEVICE" -b 2>/dev/null || true

  APP_PATH="build/ios/iphonesimulator/Runner.app"
  if [ "$SKIP_BUILD" -eq 0 ] || [ ! -d "$APP_PATH" ]; then
    echo "▶ シミュレータ向けにビルド"
    flutter build ios --simulator --debug
  fi
  [ -d "$APP_PATH" ] || { echo "✗ ビルド成果物が見つかりません: $APP_PATH"; exit 1; }

  BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")
  echo "▶ インストール: $BUNDLE_ID"
  xcrun simctl install booted "$APP_PATH"
  xcrun simctl launch booted "$BUNDLE_ID" >/dev/null

  echo "  ※ Xcode 27 には Simulator.app が同梱されないため、GUI 操作が必要な場合は"
  echo "     Android 実機を USB 接続して --android で実行することを推奨します。"
fi

cat <<'EOS'

─────────────────────────────────────────────
アプリが起動しました。次の手順でキャプチャします。

  1. 端末で対象画面を開く
  2. 下のコマンドを実行する

     ./store_assets/snap.sh grid        コレクション(グリッド)画面
     ./store_assets/snap.sh search      検索画面 (タグ選択が見える状態)
     ./store_assets/snap.sh ranking     マイランキング画面
     ./store_assets/snap.sh analytics   統計画面
     ./store_assets/snap.sh browser     ブラウザタブのホーム画面
     ./store_assets/snap.sh ai          AIタグ提案 / AIサマリー

  3. 全部そろったら合成

     node store_assets/render.mjs

  ※ 引数なしで ./store_assets/snap.sh を叩くと取得状況を確認できます
  ※ スクショに写るデータは中立的な内容にしてください (ストア審査対策)
─────────────────────────────────────────────
EOS
