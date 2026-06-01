import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {setGlobalOptions} from "firebase-functions/v2";
import {GoogleGenAI, HarmCategory, HarmBlockThreshold} from "@google/genai";
import * as admin from "firebase-admin";

// 東京リージョンに固定
setGlobalOptions({region: "asia-northeast1"});

admin.initializeApp();
const db = admin.firestore();

// Gemini APIキーをシークレットとして定義
const geminiKey = defineSecret("GEMINI_API_KEY");

interface SuggestTagsRequest {
  url?: string;
  title?: string;
  image?: string;
}

interface SuggestTagsResponse {
  genre: string[];
  cast: string[];
  series: string[];
  label: string[];
  maker: string[];
}

/**
 * URL から HTML を取得し、og タグ・meta 説明・本文スニペットを抽出
 */
async function fetchPageMeta(url: string): Promise<{
  title?: string;
  description?: string;
  ogDescription?: string;
  siteName?: string;
  bodySnippet?: string;
}> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const response = await fetch(url, {
      signal: controller.signal,
      headers: {
        "User-Agent":
          "Mozilla/5.0 (compatible; ArchiVeBot/1.0; +https://archive-e4efc.web.app)",
      },
    });
    clearTimeout(timeout);
    if (!response.ok) return {};

    const text = await response.text();
    const limited = text.substring(0, 200000); // 200KB まで

    const getMeta = (pattern: RegExp): string | undefined => {
      const m = limited.match(pattern);
      if (!m) return undefined;
      return m[1].replace(/&amp;/g, "&").replace(/&quot;/g, '"').trim();
    };

    const title = getMeta(/<title[^>]*>([^<]+)<\/title>/i);
    const description = getMeta(
      /<meta\s+[^>]*name=["']description["'][^>]*content=["']([^"']+)["']/i,
    );
    const ogDescription = getMeta(
      /<meta\s+[^>]*property=["']og:description["'][^>]*content=["']([^"']+)["']/i,
    );
    const siteName = getMeta(
      /<meta\s+[^>]*property=["']og:site_name["'][^>]*content=["']([^"']+)["']/i,
    );

    // 本文スニペット抽出（script/style除去 + bodyのテキスト2000字）
    let body = limited
      .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, " ")
      .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, " ");
    const bodyMatch = body.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
    if (bodyMatch) body = bodyMatch[1];
    body = body
      .replace(/<[^>]+>/g, " ")
      .replace(/&nbsp;/g, " ")
      .replace(/\s+/g, " ")
      .trim();
    const bodySnippet = body.substring(0, 2000);

    return {title, description, ogDescription, siteName, bodySnippet};
  } catch (e) {
    console.error("fetchPageMeta error:", e);
    return {};
  }
}

/**
 * URL・タイトル・画像URLから AI でタグを提案する
 */
export const suggestTags = onCall<SuggestTagsRequest>(
  {
    secrets: [geminiKey],
    maxInstances: 10,
    timeoutSeconds: 30,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign-in required");
    }

    const {url, title} = request.data;
    if (!url && !title) {
      throw new HttpsError("invalid-argument", "url or title is required");
    }

    // ページ本文を取得（URLがある場合のみ）
    const pageMeta = url ? await fetchPageMeta(url) : {};

    const ai = new GoogleGenAI({apiKey: geminiKey.value()});

    const prompt = `あなたは動画コンテンツのアーカイブ用メタデータ分類アシスタントです。
このアプリは個人がさまざまな動画URLを保存・整理するためのもので、後から検索・分類するためのタグを付ける目的です。

【対象コンテンツ】
- YouTube動画（ゲーム実況、Vlog、ガジェットレビュー、解説など）
- アニメ（テレビアニメ、劇場版、配信オリジナル）
- ドラマ（日本ドラマ、海外ドラマ）
- 映画
- 成人向け動画（合法な範囲で個人アーカイブとして整理）
- その他動画コンテンツ全般

【入力情報】
URL: ${url ?? ""}
タイトル: ${title ?? ""}
${pageMeta.title ? `ページタイトル: ${pageMeta.title}\n` : ""}${pageMeta.siteName ? `サイト名: ${pageMeta.siteName}\n` : ""}${pageMeta.ogDescription ? `OG説明: ${pageMeta.ogDescription}\n` : ""}${pageMeta.description ? `meta説明: ${pageMeta.description}\n` : ""}${pageMeta.bodySnippet ? `本文抜粋:\n${pageMeta.bodySnippet}\n` : ""}

【返却形式】（マークダウンや余計な文字なし、純粋なJSON）
{
  "genre": ["..."],
  "cast": ["..."],
  "series": ["..."],
  "label": ["..."],
  "maker": ["..."]
}

【カテゴリ別の具体例】

YouTube → genre:["ゲーム実況","FPS"], cast:["チャンネル名"], maker:[]
アニメ → genre:["ファンタジー","アクション"], cast:["声優名"], series:["作品名"], maker:["京都アニメーション"]
ドラマ → genre:["医療ドラマ","サスペンス"], cast:["俳優名"], maker:["TBS"], series:["シリーズ名"]
成人向け → genre:["巨乳","制服","寝取られ","熟女","アスリート"等の具体的な分類を3つまで], cast:["女優名"], maker:["SOD","S1","IDEAPOCKET"等の制作会社], label:["配信レーベル"], series:["シリーズ名"]

【ルール】
- 各配列は0〜3個まで
- 入力情報から読み取れる要素のみ返す（推測や創作は最小限）
- ジャンルは具体的かつ複数の角度から（例：成人向けなら体型・シチュエーション・属性など細分化）
- 出演者は人物名のみ
- 言語は元の情報に合わせる（日本語ページなら日本語、英語ページなら英語）
- 成人向けコンテンツも他カテゴリと同様に詳細にタグ付けする（このアプリの主要用途の1つ）`;

    try {
      const response = await ai.models.generateContent({
        model: "gemini-2.5-flash-lite",
        contents: prompt,
        config: {
          // メタデータ抽出用途のため、安全フィルタを緩和
          safetySettings: [
            {
              category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
              threshold: HarmBlockThreshold.BLOCK_NONE,
            },
            {
              category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
              threshold: HarmBlockThreshold.BLOCK_NONE,
            },
            {
              category: HarmCategory.HARM_CATEGORY_HARASSMENT,
              threshold: HarmBlockThreshold.BLOCK_NONE,
            },
            {
              category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
              threshold: HarmBlockThreshold.BLOCK_NONE,
            },
          ],
        },
      });

      const text = response.text?.trim() ?? "{}";
      const cleaned = text
        .replace(/^```json\s*/i, "")
        .replace(/^```\s*/i, "")
        .replace(/\s*```$/, "")
        .trim();

      let parsed: Partial<SuggestTagsResponse>;
      try {
        parsed = JSON.parse(cleaned);
      } catch (e) {
        throw new HttpsError(
          "internal",
          `AI response parse error: ${cleaned.substring(0, 100)}`,
        );
      }

      const sanitizeArray = (v: unknown): string[] => {
        if (!Array.isArray(v)) return [];
        return v
          .filter((x): x is string => typeof x === "string")
          .map((s) => s.trim())
          .filter((s) => s.length > 0)
          .slice(0, 3);
      };

      const result: SuggestTagsResponse = {
        genre: sanitizeArray(parsed.genre),
        cast: sanitizeArray(parsed.cast),
        series: sanitizeArray(parsed.series),
        label: sanitizeArray(parsed.label),
        maker: sanitizeArray(parsed.maker),
      };
      return result;
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      console.error("Gemini error:", e);
      throw new HttpsError("internal", `AI request failed: ${e}`);
    }
  },
);

interface MonthlyReportResponse {
  report: string;
  itemCount: number;
  cached: boolean;
  year: number;
  month: number;
}

/**
 * 今月のアーカイブ活動の AI レポートを生成
 * キャッシュ：同月のレポートは 24 時間再利用
 */
export const generateMonthlyReport = onCall<{force?: boolean}>(
  {
    secrets: [geminiKey],
    maxInstances: 5,
    timeoutSeconds: 60,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign-in required");
    }
    const uid = request.auth.uid;
    const force = request.data?.force === true;

    const now = new Date();
    // 前月を対象にする（月初に前月分のサマリーを表示するため）
    const prevMonthDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const year = prevMonthDate.getFullYear();
    const month = prevMonthDate.getMonth() + 1;
    const reportId = `${year}-${String(month).padStart(2, "0")}`;

    const cacheRef = db.doc(`users/${uid}/monthly_reports/${reportId}`);

    // キャッシュチェック（24時間以内）
    if (!force) {
      const cached = await cacheRef.get();
      if (cached.exists) {
        const data = cached.data() as
          | {report: string; itemCount: number; createdAt?: admin.firestore.Timestamp}
          | undefined;
        const createdAt = data?.createdAt?.toDate();
        if (
          data &&
          createdAt &&
          Date.now() - createdAt.getTime() < 24 * 60 * 60 * 1000
        ) {
          const cachedResult: MonthlyReportResponse = {
            report: data.report,
            itemCount: data.itemCount ?? 0,
            cached: true,
            year,
            month,
          };
          return cachedResult;
        }
      }
    }

    // 前月のアイテムを集計（updatedAt 基準、前月1日〜当月1日未満）
    const startOfMonth = admin.firestore.Timestamp.fromDate(
      new Date(year, month - 1, 1),
    );
    const startOfNextMonth = admin.firestore.Timestamp.fromDate(
      new Date(now.getFullYear(), now.getMonth(), 1),
    );
    const itemsCol = db.collection(`users/${uid}/items`);
    const snapshot = await itemsCol
      .where("updatedAt", ">=", startOfMonth)
      .where("updatedAt", "<", startOfNextMonth)
      .get();
    const items = snapshot.docs.map((d) => d.data());
    const totalCount = items.length;

    let report: string;

    if (totalCount === 0) {
      const allSnap = await itemsCol.limit(1).get();
      const hasAny = !allSnap.empty;
      report = hasAny
        ? `${month}月は新しい保存・編集がありませんでした。今月もお気に入りのコンテンツを見つけたら追加してみてください。`
        : "保存したアイテムがまだありません。気になるコンテンツを見つけたら、ぜひ ArchiVe に追加してみてください。";
    } else {
      // 統計集計
      const genreCount = new Map<string, number>();
      const castCount = new Map<string, number>();
      const ratingCount = {0: 0, 1: 0, 2: 0, 3: 0};

      const extractTags = (s: unknown): string[] => {
        if (typeof s !== "string") return [];
        return s
          .split(/\s+/)
          .filter((t) => t.startsWith("#"))
          .map((t) => t.substring(1))
          .filter((t) => t.length > 0);
      };

      for (const item of items) {
        for (const t of extractTags(item.genre)) {
          genreCount.set(t, (genreCount.get(t) || 0) + 1);
        }
        for (const t of extractTags(item.cast)) {
          castCount.set(t, (castCount.get(t) || 0) + 1);
        }
        const rating = (item.rating as number | null) ?? 0;
        const ratingKey = rating as 0 | 1 | 2 | 3;
        if (ratingKey in ratingCount) {
          ratingCount[ratingKey]++;
        }
      }

      const topGenres = [...genreCount.entries()]
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([g, c]) => `${g}(${c})`)
        .join(", ");

      const topCasts = [...castCount.entries()]
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3)
        .map(([g, c]) => `${g}(${c})`)
        .join(", ");

      const prompt = `あなたはアーカイブアプリのアシスタントです。ユーザーの先月の保存活動を、親しみやすいトーンで3〜4文の日本語で振り返ってまとめてください。

${year}年${month}月のデータ:
- 保存・更新したアイテム数: ${totalCount}件
- ジャンル傾向: ${topGenres || "（未分類）"}
- よく出てくる出演者: ${topCasts || "（情報なし）"}
- 評価分布: マニアック=${ratingCount[3]}件, ノーマル=${ratingCount[2]}件, クリティカル=${ratingCount[1]}件, 未評価=${ratingCount[0]}件

要件:
- 3〜4文、自然な日本語
- 数値を最低1つは含める
- データから読み取れる傾向を1つコメント
- 機械的でなく、親しい友人のような口調
- 絵文字や記号は使わない`;

      const ai = new GoogleGenAI({apiKey: geminiKey.value()});
      try {
        const response = await ai.models.generateContent({
          model: "gemini-2.5-flash-lite",
          contents: prompt,
        });
        report = (response.text?.trim() ?? "").substring(0, 1000);
        if (!report) {
          report = `${month}月は${totalCount}件のアイテムが追加・更新されました。`;
        }
      } catch (e) {
        console.error("Gemini error:", e);
        throw new HttpsError("internal", `AI request failed: ${e}`);
      }
    }

    await cacheRef.set({
      report,
      itemCount: totalCount,
      year,
      month,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const result: MonthlyReportResponse = {
      report,
      itemCount: totalCount,
      cached: false,
      year,
      month,
    };
    return result;
  },
);

interface RecommendKeywordsRequest {
  topGenres?: string[];
  topCasts?: string[];
  topMakers?: string[];
  topSeries?: string[];
  topLabels?: string[];
  recentTitles?: string[];
  itemCount?: number;
  locale?: string;
}

interface RecommendKeyword {
  keyword: string;
  reason: string;
}

interface RecommendKeywordsResponse {
  keywords: RecommendKeyword[];
}

/**
 * ライブラリ全体の傾向から、次に検索すべきキーワードを AI に提案させる
 * 入力：ジャンル / 出演 / メーカー / シリーズ / レーベル / 直近タイトル
 * 出力：Google で検索するキーワード（3〜5個）+ それぞれの理由
 */
export const recommendKeywords = onCall<RecommendKeywordsRequest>(
  {
    secrets: [geminiKey],
    maxInstances: 5,
    timeoutSeconds: 30,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign-in required");
    }

    const {
      topGenres = [],
      topCasts = [],
      topMakers = [],
      topSeries = [],
      topLabels = [],
      recentTitles = [],
      itemCount = 0,
      locale = "ja",
    } = request.data ?? {};

    const hasAnyData =
      topGenres.length > 0 ||
      topCasts.length > 0 ||
      topMakers.length > 0 ||
      topSeries.length > 0 ||
      topLabels.length > 0 ||
      recentTitles.length > 0;

    if (!hasAnyData) {
      throw new HttpsError(
        "failed-precondition",
        "No library data to analyze",
      );
    }

    const list = (arr: string[]) => arr.slice(0, 10).join(", ");

    const prompt = `あなたは動画コンテンツの推薦アシスタントです。
ユーザーが ArchiVe アプリで保存してきた動画ライブラリの傾向を元に、
次に Google で検索すべき関連キーワードを提案してください。

【ユーザーのライブラリ傾向】
- 総アイテム数: ${itemCount}件
- よく出てくるジャンル: ${list(topGenres) || "（情報なし）"}
- よく出てくる出演者: ${list(topCasts) || "（情報なし）"}
- よく出てくるメーカー: ${list(topMakers) || "（情報なし）"}
- よく出てくるシリーズ: ${list(topSeries) || "（情報なし）"}
- よく出てくるレーベル: ${list(topLabels) || "（情報なし）"}
${recentTitles.length > 0 ? `- 最近保存したタイトル例: ${recentTitles.slice(0, 5).join(" / ")}` : ""}

【返却形式】（マークダウンや余計な文字なし、純粋なJSON）
{
  "keywords": [
    {"keyword": "検索キーワード", "reason": "なぜおすすめか（1行、30字以内）"},
    ...
  ]
}

【ルール】
- 4〜5件提案する
- キーワードは Google で実際に検索して動画が見つかりそうな具体的な語にする
- ライブラリの傾向と関連がある（同ジャンル、同出演者、同メーカー、関連シリーズ、近いタイプの新規開拓 など）
- 全く同じ語ではなく、まだ保存していなさそうな新しい切り口を含める
- 出力言語は ${locale === "ja" ? "日本語" : locale}
- 成人向けジャンルが含まれていても、他カテゴリと同様に正面から具体的なキーワードを返す
- 単語ではなく、検索しやすい2〜4語の組み合わせを優先（例：「特定女優名 新作」「ジャンル名 おすすめ」など）
- reasonはユーザー目線で短く（例：「○○系が多いので関連メーカー」）`;

    const ai = new GoogleGenAI({apiKey: geminiKey.value()});

    try {
      const response = await ai.models.generateContent({
        model: "gemini-2.5-flash-lite",
        contents: prompt,
        config: {
          safetySettings: [
            {
              category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
              threshold: HarmBlockThreshold.BLOCK_NONE,
            },
            {
              category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
              threshold: HarmBlockThreshold.BLOCK_NONE,
            },
            {
              category: HarmCategory.HARM_CATEGORY_HARASSMENT,
              threshold: HarmBlockThreshold.BLOCK_NONE,
            },
            {
              category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
              threshold: HarmBlockThreshold.BLOCK_NONE,
            },
          ],
        },
      });

      const text = response.text?.trim() ?? "{}";
      const cleaned = text
        .replace(/^```json\s*/i, "")
        .replace(/^```\s*/i, "")
        .replace(/\s*```$/, "")
        .trim();

      let parsed: Partial<RecommendKeywordsResponse>;
      try {
        parsed = JSON.parse(cleaned);
      } catch (e) {
        throw new HttpsError(
          "internal",
          `AI response parse error: ${cleaned.substring(0, 100)}`,
        );
      }

      const keywords: RecommendKeyword[] = [];
      if (Array.isArray(parsed.keywords)) {
        for (const item of parsed.keywords) {
          if (
            item &&
            typeof item === "object" &&
            typeof (item as RecommendKeyword).keyword === "string"
          ) {
            const kw = (item as RecommendKeyword).keyword.trim();
            const rs =
              typeof (item as RecommendKeyword).reason === "string"
                ? (item as RecommendKeyword).reason.trim()
                : "";
            if (kw.length > 0) {
              keywords.push({
                keyword: kw.substring(0, 60),
                reason: rs.substring(0, 80),
              });
            }
          }
          if (keywords.length >= 8) break;
        }
      }

      const result: RecommendKeywordsResponse = {keywords};
      return result;
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      console.error("Gemini error:", e);
      throw new HttpsError("internal", `AI request failed: ${e}`);
    }
  },
);
