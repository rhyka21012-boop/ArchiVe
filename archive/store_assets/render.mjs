#!/usr/bin/env node
/**
 * ストア掲載用スクリーンショットを headless Chrome で合成する。
 *
 * 使い方:
 *   node store_assets/render.mjs                        # 全サイズ × ja
 *   node store_assets/render.mjs --locale ja,en         # 複数言語
 *   node store_assets/render.mjs --size ios69           # サイズ絞り込み
 *   node store_assets/render.mjs --only 01-collection   # 1枚だけ
 *
 * 出力: store_assets/out/<size>/<locale>/<id>.png
 */
import { readFileSync, writeFileSync, mkdirSync, existsSync, rmSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(fileURLToPath(import.meta.url));
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

/** 端末画面の縦横比 (フレーム内の描画領域) */
const SCREEN_RATIO = 2796 / 1290; // ≒ 2.167

/**
 * ストア要求サイズ (portrait)。
 * frameRatio = 出力幅に対するデバイスフレーム幅の比率。
 * 下端がわずかに画面外へ抜ける / ほぼ接する値にして「下まで使い切る」構図にする。
 */
const SIZES = {
  // App Store 6.9" (iPhone 17 Pro Max 等) — 現在の必須サイズ
  ios69: { w: 1290, h: 2796, frameRatio: 0.86 },
  // App Store iPad 13" — 出力が横長なのでフレーム比率は小さめ
  ipad13: { w: 2048, h: 2732, frameRatio: 0.48 },
  // Google Play (9:16)
  play: { w: 1080, h: 1920, frameRatio: 0.68 },
};

// ---------- CLI ----------
function arg(name, fallback) {
  const i = process.argv.indexOf(`--${name}`);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}
const locales = arg('locale', 'ja').split(',').map((s) => s.trim());
const sizeKeys = arg('size', Object.keys(SIZES).join(',')).split(',').map((s) => s.trim());
const only = arg('only', null);

// ---------- 入力 ----------
if (!existsSync(CHROME)) {
  console.error(`✗ Chrome が見つかりません: ${CHROME}`);
  process.exit(1);
}
const config = JSON.parse(readFileSync(join(ROOT, 'config.json'), 'utf8'));
const template = readFileSync(join(ROOT, 'template/screenshot.html'), 'utf8');

const TMP = join(ROOT, '.tmp');
mkdirSync(TMP, { recursive: true });

/** サイズに応じてレイアウト値をスケールする (幅 1290px を基準に比例) */
function layout(size) {
  const k = size.w / 1290;
  const frameW = Math.round(size.w * size.frameRatio);
  const frameH = Math.round(frameW * SCREEN_RATIO);
  return {
    W: size.w,
    H: size.h,
    FRAME_W: frameW,
    FRAME_H: frameH,
    FRAME_RADIUS: Math.round(frameW * 0.075),
    SCREEN_RADIUS: Math.round(frameW * 0.062),
    BEZEL: Math.max(6, Math.round(frameW * 0.017)),
    SHADOW_Y: Math.round(28 * k),
    SHADOW_BLUR: Math.round(70 * k),
    ISLAND_TOP: Math.round(frameW * 0.026),
    ISLAND_W: Math.round(frameW * 0.30),
    ISLAND_H: Math.round(frameW * 0.048),
    CAPTION_SIZE: Math.round(64 * k),
    SUBCAPTION_SIZE: Math.round(32 * k),
    CAP_PAD_TOP: Math.round(120 * k),
    CAP_PAD_X: Math.round(96 * k),
    SUB_MARGIN: Math.round(24 * k),
    DEVICE_PAD_TOP: Math.round(72 * k),
    GLOW_BLUR: Math.round(150 * k),
    GLOW_A: Math.round(720 * k),
    GLOW_A_TOP: Math.round(-200 * k),
    GLOW_A_LEFT: Math.round(-180 * k),
    GLOW_B: Math.round(640 * k),
    GLOW_B_BOTTOM: Math.round(-160 * k),
    GLOW_B_RIGHT: Math.round(-200 * k),
    PH_GAP: Math.round(28 * k),
    PH_FONT: Math.round(30 * k),
    PH_PAD: Math.round(40 * k),
    PH_ICON: Math.round(150 * k),
    PH_ICON_R: Math.round(34 * k),
    PH_BORDER: Math.max(2, Math.round(3 * k)),
    PH_ICON_FONT: Math.round(64 * k),
  };
}

function fill(tpl, vars) {
  return tpl.replace(/\{\{(\w+)\}\}/g, (m, key) =>
    Object.prototype.hasOwnProperty.call(vars, key) ? String(vars[key]) : m
  );
}

// ---------- レンダリング ----------
let count = 0;
let placeholderCount = 0;

for (const sizeKey of sizeKeys) {
  const size = SIZES[sizeKey];
  if (!size) {
    console.warn(`! 未知のサイズ: ${sizeKey} (有効: ${Object.keys(SIZES).join(', ')})`);
    continue;
  }
  const lay = layout(size);

  for (const locale of locales) {
    const outDir = join(ROOT, 'out', sizeKey, locale);
    mkdirSync(outDir, { recursive: true });

    for (const slide of config.slides) {
      if (only && slide.id !== only) continue;

      const theme = slide.dark ? config.themeDark : config.theme;
      const caption = slide.caption[locale] ?? slide.caption.ja;
      const subcaption = slide.subcaption[locale] ?? slide.subcaption.ja;

      // 実キャプチャの有無で表示内容と island の出し分けを決める
      const capturePath = join(ROOT, 'captures', slide.capture);
      const hasCapture = existsSync(capturePath);
      if (!hasCapture) placeholderCount++;

      const screenContent = hasCapture
        ? `<img src="file://${capturePath}" alt="">`
        : `<div class="placeholder">
             <div class="ph-icon">▶</div>
             <div>captures/${slide.capture}<br>を配置してください</div>
           </div>`;

      const html = fill(template, {
        ...lay,
        ACCENT: theme.accent,
        ACCENT2: theme.accent2,
        BG_TOP: theme.bgTop,
        BG_BOTTOM: theme.bgBottom,
        TEXT_COLOR: theme.textColor,
        TEXT_SUB_COLOR: theme.textSubColor,
        CAPTION: caption,
        SUBCAPTION: subcaption,
        SCREEN_CONTENT: screenContent,
        // 実キャプチャにはステータスバーが写るため island は重ねない
        ISLAND_DISPLAY: hasCapture ? 'none' : 'block',
      });

      const tmpHtml = join(TMP, `${sizeKey}-${locale}-${slide.id}.html`);
      const outPng = join(outDir, `${slide.id}.png`);
      writeFileSync(tmpHtml, html, 'utf8');

      execFileSync(CHROME, [
        '--headless',
        '--disable-gpu',
        '--hide-scrollbars',
        '--force-device-scale-factor=1',
        '--allow-file-access-from-files',
        `--window-size=${size.w},${size.h}`,
        `--screenshot=${outPng}`,
        `file://${tmpHtml}`,
      ], { stdio: 'ignore' });

      console.log(`✓ ${sizeKey}/${locale}/${slide.id}.png  (${size.w}x${size.h})${hasCapture ? '' : '  [placeholder]'}`);
      count++;
    }
  }
}

rmSync(TMP, { recursive: true, force: true });
console.log(`\n完了: ${count} 枚を store_assets/out/ に出力しました。`);
if (placeholderCount > 0) {
  console.log(`※ ${placeholderCount} 枚はプレースホルダです。./store_assets/capture.sh で実画面を取得してください。`);
}
