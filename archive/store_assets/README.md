# ストア掲載用スクリーンショット生成

App Store / Google Play 用のスクリーンショットを、実画面キャプチャ + HTML 合成で生成するパイプライン。

## 構成

```
store_assets/
├── template/screenshot.html  合成テンプレート (CSS でデバイスフレームを自作)
├── config.json               スライド定義 (キャプション × 言語、配色)
├── render.mjs                headless Chrome でレンダリング
├── capture.sh                端末準備 + アプリのビルド/インストール/起動
├── snap.sh                   表示中の画面を1枚キャプチャ
├── captures/                 アプリ実画面 (git 管理外)
└── out/                      完成品 (git 管理外)
```

## 使い方

### 1. 端末でアプリを起動

```bash
./store_assets/capture.sh                  # Android 実機 / iOS シミュレータを自動判別
./store_assets/capture.sh --android        # Android を強制
./store_assets/capture.sh --ios            # iOS シミュレータを強制
./store_assets/capture.sh --skip-build     # ビルド済み APK を再利用 (高速)
./store_assets/capture.sh --skip-install   # 入っているアプリをそのまま起動
./store_assets/capture.sh --release        # release 署名でビルド (既定は debug)
```

> **Android では debug 署名が既定です。** 開発中に入れたビルドは debug 鍵で署名されているため、
> release 鍵の APK を入れようとすると `INSTALL_FAILED_UPDATE_INCOMPATIBLE` になり、
> 解消にはアンインストール（＝**作品データの全消去**）が必要になります。
> `main.dart` で `debugShowCheckedModeBanner: false` にしているため、
> debug ビルドでも DEBUG リボンは出ず、撮影上の見た目は release と同じです。

ビルド → インストール → 起動までを自動で行います。

> **現状 Android 実機を推奨します。** この環境の Xcode 27 には Simulator.app が同梱されておらず、
> シミュレータの GUI 操作ができないため画面遷移ができません。
>
> `adb` が PATH に無い場合も `~/Library/Android/sdk/platform-tools` 等を自動探索します。
> 恒久的に通すなら `~/.zshrc` に以下を追加してください。
>
> ```bash
> export ANDROID_HOME="$HOME/Library/Android/sdk"
> export PATH="$PATH:$ANDROID_HOME/platform-tools"
> ```

### 2. 画面ごとにキャプチャ

端末で対象画面を開いてから、対応するコマンドを実行します。

```bash
./store_assets/snap.sh grid        # コレクション(グリッド)画面
./store_assets/snap.sh search      # 検索画面 (タグ選択が見える状態)
./store_assets/snap.sh ranking     # マイランキング画面
./store_assets/snap.sh analytics   # 統計画面
./store_assets/snap.sh browser     # ブラウザタブのホーム画面
./store_assets/snap.sh ai          # AIタグ提案 / AIサマリー

./store_assets/snap.sh             # 引数なし = 取得状況の確認
```

撮影前にステータスバーを整えると仕上がりが揃います (Android のみ)。

```bash
./store_assets/snap.sh --demo-on    # 9:41 / 電池100% / 電波最大 / 通知非表示
./store_assets/snap.sh --demo-off   # 元に戻す
```

端末の実際の設定は変更されず、`--demo-off` か再起動で完全に戻ります。

> **画面遷移は手動です。** `integration_test` / `idb` が未導入のため UI 自動操作ができません。
> 完全自動化したい場合は `pubspec.yaml` に `integration_test` を追加してドライバテストを書く必要があります。

### 3. 合成

```bash
node store_assets/render.mjs                      # 全サイズ × ja
node store_assets/render.mjs --locale ja,en       # 複数言語
node store_assets/render.mjs --size ios69          # サイズ絞り込み
node store_assets/render.mjs --only 01-collection  # 1枚だけ (試作時に便利)
```

出力: `out/<size>/<locale>/<id>.png`

キャプチャ未配置でもプレースホルダで合成されるため、**テイスト調整だけ先に進められます**。

### 出力サイズ

| キー | 解像度 | 用途 |
|---|---|---|
| `ios69` | 1290×2796 | App Store 6.9"（必須） |
| `ipad13` | 2048×2732 | App Store iPad 13" |
| `play` | 1080×1920 | Google Play |

## カスタマイズ

- **キャプション / 配色** → `config.json`
- **レイアウト（余白・フォントサイズ・フレーム比率）** → `render.mjs` の `layout()` と `SIZES`
- **デザイン全体** → `template/screenshot.html`

`layout()` は幅 1290px を基準に比例スケールするため、サイズ追加は `SIZES` に 1 行足すだけで全レイアウトが追従します。

## 多言語展開

`config.json` の `caption` / `subcaption` に言語キーを追加すれば `--locale` で出力できます。
未定義の言語は `ja` にフォールバックします。

## 注意

- デバイスフレームは CSS で描いたオリジナル形状です（既製モックアップ画像は使っていません）
- **キャプチャに写る作品は必ず中立的な内容にしてください。**
  App Store 審査ガイドライン 1.1.4 と Google Play の不適切コンテンツ ポリシーは、
  ストア掲載画像における性的表現を禁止しています。アダルト作品が1件でも写り込むと
  審査でリジェクトされ、繰り返すと開発者アカウント自体のリスクになります。
  撮影時はタグ検索やソートで表示を絞り込み、中立的な作品だけが並ぶ状態にしてください
  (作品を削除する必要はありません)
- ストアへのアップロードは手動で行ってください（App Store Connect / Play Console）
