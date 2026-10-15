#!/usr/bin/env bash
# =============================================================================
# 「今表示されている画面」を1枚キャプチャする (非対話)。
# Android 実機 / iOS シミュレータ を自動判別する。
#
# 使い方:
#   ./store_assets/snap.sh grid
#   ./store_assets/snap.sh              # 引数なしで取得状況を表示
#   ./store_assets/snap.sh --demo-on    # ステータスバーを撮影用に整える
#   ./store_assets/snap.sh --demo-off   # 元に戻す
#
# 保存先: store_assets/captures/<name>.png
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAPTURE_DIR="$SCRIPT_DIR/captures"

# config.json の capture 名と対応
VALID="grid search ranking analytics browser ai"

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

# 接続中の Android 端末 (無ければ空)。
# set -e で落ちないよう、失敗を明示的に吸収する。
ANDROID_ID=""
if [ -n "$ADB" ]; then
  ANDROID_ID="$("$ADB" devices 2>/dev/null | awk '/\tdevice$/{print $1; exit}' || true)"
fi

# 端末指定を1箇所に集約する (-s の有無で分岐させない)
adbx() {
  if [ -n "$ANDROID_ID" ]; then
    "$ADB" -s "$ANDROID_ID" "$@"
  else
    "$ADB" "$@"
  fi
}

require_adb() {
  if [ -z "$ADB" ]; then
    echo "✗ adb が見つかりません。"
    echo "  Android SDK の platform-tools を PATH に追加するか ANDROID_HOME を設定してください。"
    exit 1
  fi
  if [ -z "$ANDROID_ID" ]; then
    echo "✗ Android 端末が接続されていません。"
    exit 1
  fi
}

# ---------- ステータスバーを撮影向けに整える (Android デモモード) ----------
# 時刻・電波・電池を固定し、通知アイコンを隠す。
# 端末の実際の設定は変わらず、--demo-off か再起動で完全に元に戻る。
demo_broadcast() {
  adbx shell am broadcast -a com.android.systemui.demo "$@" >/dev/null 2>&1 || true
}

demo_on() {
  adbx shell settings put global sysui_demo_allowed 1 >/dev/null 2>&1 || true
  demo_broadcast -e command enter
  demo_broadcast -e command clock -e hhmm 0941
  demo_broadcast -e command battery -e level 100 -e plugged false
  demo_broadcast -e command network -e wifi show -e level 4
  demo_broadcast -e command network -e mobile show -e datatype none -e level 4
  demo_broadcast -e command notifications -e visible false
  echo "✓ ステータスバーを撮影用に整えました (9:41 / 電池100% / 通知非表示)"
  echo "  戻すには: ./store_assets/snap.sh --demo-off"
}

demo_off() {
  demo_broadcast -e command exit
  echo "✓ ステータスバーを元に戻しました"
}

NAME="${1:-}"

case "$NAME" in
  --demo-on)  require_adb; demo_on;  exit 0 ;;
  --demo-off) require_adb; demo_off; exit 0 ;;
esac

if [ -z "$NAME" ]; then
  echo "使い方: ./store_assets/snap.sh <name>"
  echo
  echo "  ステータスバー調整 (Android):"
  echo "    --demo-on    9:41 / 電池100% / 電波最大 / 通知非表示に固定"
  echo "    --demo-off   元に戻す"
  echo
  echo "  name に指定できる値:"
  for v in $VALID; do
    if [ -f "$CAPTURE_DIR/$v.png" ]; then
      echo "    $v  ✓ 取得済み"
    else
      echo "    $v  — 未取得"
    fi
  done
  exit 0
fi

if ! echo " $VALID " | grep -q " $NAME "; then
  echo "✗ 不明な名前: $NAME"
  echo "  有効: $VALID"
  exit 1
fi

mkdir -p "$CAPTURE_DIR"
OUT="$CAPTURE_DIR/$NAME.png"

# ---------- 撮影先を自動判別 (Android 実機 > iOS シミュレータ) ----------
if [ -n "$ANDROID_ID" ]; then
  echo "▶ Android 実機からキャプチャ ($ANDROID_ID)"
  adbx exec-out screencap -p > "$OUT"
elif xcrun simctl list devices 2>/dev/null | grep -q Booted; then
  echo "▶ iOS シミュレータからキャプチャ"
  xcrun simctl io booted screenshot --type=png "$OUT"
else
  echo "✗ 撮影対象が見つかりません。"
  if [ -z "$ADB" ]; then
    echo "  (adb が見つかりません。platform-tools を PATH に追加するか"
    echo "   ANDROID_HOME を設定してください)"
  fi
  echo "  Android 実機を USB 接続するか、iOS シミュレータを起動してください。"
  exit 1
fi

# 0 バイトなら失敗扱い
if [ ! -s "$OUT" ]; then
  echo "✗ キャプチャに失敗しました (0 バイト)"
  rm -f "$OUT"
  exit 1
fi

SIZE="$(file -b "$OUT" | grep -oE '[0-9]+ x [0-9]+' || echo '不明')"
echo "✓ captures/$NAME.png を保存しました ($SIZE)"

# 撮影内容の注意喚起 (ストア審査対策)
echo "  ※ アダルト作品が写っていないか確認してください (審査リジェクトの原因になります)"

# 残りの未取得を表示
REMAIN=""
for v in $VALID; do
  [ -f "$CAPTURE_DIR/$v.png" ] || REMAIN="$REMAIN $v"
done
if [ -n "$REMAIN" ]; then
  echo "  未取得:$REMAIN"
else
  echo "  全て取得済みです。合成を実行してください: node store_assets/render.mjs"
fi
