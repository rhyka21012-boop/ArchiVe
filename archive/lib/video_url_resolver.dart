import 'package:http/http.dart' as http;

/// ページ URL から動画直リンク (mp4 等) を推測する。
/// 対応する検出源:
/// - 拡張子が動画拡張子ならそのまま
/// - HTML 内 og:video / twitter:player:stream / <video src> / <source src>
class ResolvedVideoUrl {
  final String url;
  final String? mimeType;
  final String source; // og:video / twitter / <video src> / <source src> / direct
  const ResolvedVideoUrl({
    required this.url,
    this.mimeType,
    required this.source,
  });
}

class VideoUrlResolver {
  static final RegExp _videoExtRegex =
      RegExp(r'\.(mp4|m4v|mov|webm|mkv|m3u8)(\?.*)?$', caseSensitive: false);

  static bool looksLikeDirectVideo(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    return _videoExtRegex.hasMatch(path);
  }

  /// URL を解決する。ページ URL なら HTML を fetch してメタ抽出。
  /// タイムアウトや失敗時は null を返す。
  /// [preferredHeight] が与えられた場合、その解像度に最も近い候補を優先する。
  static Future<ResolvedVideoUrl?> resolve(String url,
      {int? preferredHeight}) async {
    if (looksLikeDirectVideo(url)) {
      return ResolvedVideoUrl(url: url, source: 'direct');
    }
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode >= 400) return null;
      final ct = (response.headers['content-type'] ?? '').toLowerCase();
      // サーバが直接動画を返した場合
      if (ct.startsWith('video/') ||
          ct == 'application/mp4' ||
          ct == 'application/x-mpegurl') {
        return ResolvedVideoUrl(url: url, mimeType: ct, source: 'direct');
      }
      // HTML 系のみパース
      if (!ct.startsWith('text/') &&
          !ct.contains('html') &&
          !ct.contains('xml') &&
          ct.isNotEmpty) {
        return null;
      }
      return _extractFromHtml(response.body, url,
          preferredHeight: preferredHeight);
    } catch (_) {
      return null;
    }
  }

  static ResolvedVideoUrl? _extractFromHtml(String html, String baseUrl,
      {int? preferredHeight}) {
    // 優先度: og:video:secure_url > og:video:url > og:video > twitter:player:stream
    //         > <video src> > <source src type=video/*> > <source src=*.mp4 等>
    final candidates = <_Candidate>[
      _Candidate(_findMeta(html, 'property', 'og:video:secure_url'),
          'og:video:secure_url'),
      _Candidate(_findMeta(html, 'property', 'og:video:url'), 'og:video:url'),
      _Candidate(_findMeta(html, 'property', 'og:video'), 'og:video'),
      _Candidate(
          _findMeta(html, 'name', 'twitter:player:stream'), 'twitter:player'),
    ];
    for (final c in candidates) {
      if (c.raw != null && c.raw!.isNotEmpty) {
        return ResolvedVideoUrl(
            url: _resolveUrl(c.raw!, baseUrl), source: c.source);
      }
    }

    // <video ... src="...">
    final videoSrc = RegExp(r'''<video[^>]*\ssrc=["']([^"']+)["']''',
            caseSensitive: false)
        .firstMatch(html);
    if (videoSrc != null) {
      return ResolvedVideoUrl(
          url: _resolveUrl(videoSrc.group(1)!, baseUrl), source: '<video src>');
    }

    // <source ... type="video/*" src="...">  (順不同を許容)
    final sourceTyped = RegExp(
      r'''<source[^>]*\stype=["']video/[^"']+["'][^>]*\ssrc=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(html);
    if (sourceTyped != null) {
      return ResolvedVideoUrl(
          url: _resolveUrl(sourceTyped.group(1)!, baseUrl),
          source: '<source type=video>');
    }
    final sourceSrcType = RegExp(
      r'''<source[^>]*\ssrc=["']([^"']+)["'][^>]*\stype=["']video/[^"']+["']''',
      caseSensitive: false,
    ).firstMatch(html);
    if (sourceSrcType != null) {
      return ResolvedVideoUrl(
          url: _resolveUrl(sourceSrcType.group(1)!, baseUrl),
          source: '<source type=video>');
    }

    // <source ... src="...mp4/webm/...">
    final sourceExt = RegExp(
      r'''<source[^>]*\ssrc=["']([^"']+\.(?:mp4|m4v|webm|mov|mkv|m3u8)(?:\?[^"']*)?)["']''',
      caseSensitive: false,
    ).firstMatch(html);
    if (sourceExt != null) {
      return ResolvedVideoUrl(
          url: _resolveUrl(sourceExt.group(1)!, baseUrl),
          source: '<source src>');
    }

    // フォールバック: HTML 中 (JS プレイヤー内など) に埋め込まれた動画 URL を抽出
    // 例: xvideos の setVideoUrlHigh('https://...mp4?secure=...'),
    //     多くのストリーミングサイトが同様のパターン
    final embedded = _extractEmbeddedUrls(html);
    if (embedded.isNotEmpty) {
      // preferredHeight が与えられた場合、その解像度に一致する URL を優先
      _RankedUrl best;
      if (preferredHeight != null) {
        // 1) 完全一致
        final exact =
            embedded.where((r) => r.heightHint == preferredHeight).toList();
        if (exact.isNotEmpty) {
          exact.sort((a, b) => b.score.compareTo(a.score));
          best = exact.first;
        } else {
          // 2) preferredHeight 以下で最大 (画質不足だが超過より安全)
          final lower = embedded
              .where((r) =>
                  r.heightHint != null && r.heightHint! <= preferredHeight)
              .toList();
          if (lower.isNotEmpty) {
            lower.sort((a, b) => b.heightHint!.compareTo(a.heightHint!));
            best = lower.first;
          } else {
            // 3) 何もなければ全体最高
            embedded.sort((a, b) => b.score.compareTo(a.score));
            best = embedded.first;
          }
        }
      } else {
        embedded.sort((a, b) => b.score.compareTo(a.score));
        best = embedded.first;
      }
      return ResolvedVideoUrl(
        url: _resolveUrl(best.url, baseUrl),
        source: 'embedded',
      );
    }

    return null;
  }

  /// HTML 全体から動画 URL を抜き出す (JS 埋め込みも含む)。
  /// エスケープ済みスラッシュ (`\/`) も考慮する。
  static List<_RankedUrl> _extractEmbeddedUrls(String html) {
    // JS 内ではスラッシュが `\/` にエスケープされているケースがあるので正規化
    final normalized = html.replaceAll(r'\/', '/');
    final urlRegex = RegExp(
      r'''https?://[^\s"'<>()\\]+?\.(?:mp4|m4v|webm|mov|mkv|m3u8)(?:\?[^\s"'<>()\\]*)?''',
      caseSensitive: false,
    );
    final seen = <String>{};
    final results = <_RankedUrl>[];
    for (final m in urlRegex.allMatches(normalized)) {
      final url = m.group(0)!;
      if (seen.contains(url)) continue;
      seen.add(url);
      // URL の直前 40 文字だけをコンテキストとする (「setVideoUrlHigh(」等の呼び出し名が
      // ちょうど URL の直前にあるパターンを狙う)。後方に隣接する別 URL 用の
      // キーワードが混入するのを避けるため、後方は含めない。
      final ctxStart = (m.start - 40).clamp(0, normalized.length);
      final context = normalized.substring(ctxStart, m.start);
      results.add(_RankedUrl(
        url,
        _qualityScore(url, context),
        heightHint: _guessHeight(url, context),
      ));
    }
    return results;
  }

  /// URL/コンテキストから解像度 (240/360/480/720/1080/1440/2160) を推定。
  static int? _guessHeight(String url, String context) {
    final combined = '${url.toLowerCase()} ${context.toLowerCase()}';
    for (final h in [2160, 1440, 1080, 720, 540, 480, 360, 240]) {
      if (RegExp(r'(^|[^0-9])' + h.toString() + r'([^0-9]|$)')
          .hasMatch(combined)) {
        return h;
      }
    }
    return null;
  }

  /// URL とその周辺コンテキストから品質スコアを算出。
  /// スコアが高いほど優先される。
  static int _qualityScore(String url, String context) {
    int score = 0;
    final u = url.toLowerCase();
    final c = context.toLowerCase();
    // HLS は最後の手段
    if (u.endsWith('.m3u8') || u.contains('.m3u8?')) score -= 50;
    // 解像度キーワード
    if (u.contains('2160') || c.contains('2160') || c.contains('4k')) {
      score += 200;
    } else if (u.contains('1440') || c.contains('1440')) {
      score += 150;
    } else if (u.contains('1080') || c.contains('1080')) {
      score += 100;
    } else if (u.contains('720') || c.contains('720')) {
      score += 70;
    } else if (u.contains('540') || c.contains('540')) {
      score += 40;
    } else if (u.contains('480') || c.contains('480')) {
      score += 30;
    } else if (u.contains('360') || c.contains('360')) {
      score += 15;
    } else if (u.contains('240') || c.contains('240')) {
      score += 5;
    }
    // 品質キーワード (xvideos の setVideoUrlHigh 等)
    if (c.contains('videourlhigh') ||
        c.contains('urlhigh') ||
        c.contains('_high') ||
        c.contains('"high"') ||
        c.contains("'high'")) {
      score += 60;
    } else if (c.contains('videourlmedium') ||
        c.contains('urlmedium') ||
        c.contains('_medium')) {
      score += 40;
    } else if (c.contains('videourllow') ||
        c.contains('urllow') ||
        c.contains('_low') ||
        c.contains('"low"') ||
        c.contains("'low'")) {
      score += 10;
    }
    if (c.contains('hd') || u.contains('_hd')) score += 20;
    // mp4 は m3u8 より優先
    if (u.contains('.mp4')) score += 30;
    return score;
  }

  static String? _findMeta(String html, String attr, String value) {
    // <meta property="og:video" content="URL">  or  <meta content="URL" property="og:video">
    final escValue = RegExp.escape(value);
    final r1 = RegExp(
      '''<meta[^>]*\\s$attr=["']$escValue["'][^>]*\\scontent=["']([^"']+)["']''',
      caseSensitive: false,
    );
    final r2 = RegExp(
      '''<meta[^>]*\\scontent=["']([^"']+)["'][^>]*\\s$attr=["']$escValue["']''',
      caseSensitive: false,
    );
    return r1.firstMatch(html)?.group(1) ?? r2.firstMatch(html)?.group(1);
  }

  static String _resolveUrl(String maybeRelative, String baseUrl) {
    final decoded = _decodeHtmlEntities(maybeRelative);
    // 既に絶対 URL なら Uri.parse を通さない (クエリ内の `==` 等を維持)
    if (decoded.startsWith('http://') || decoded.startsWith('https://')) {
      return decoded;
    }
    try {
      return Uri.parse(baseUrl).resolve(decoded).toString();
    } catch (_) {
      return decoded;
    }
  }

  /// 実際にダウンロード可能な解像度の集合を返す。
  /// - HTML fetch に失敗 / 直リンク / 解像度が推定不可なら null (呼び出し側で全解像度を有効化)
  /// - 検出できた場合はその解像度の Set (例: {720, 480})
  static Future<Set<int>?> probeAvailableHeights(String url) async {
    if (looksLikeDirectVideo(url)) return null; // 直リンクは解像度不明
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode >= 400) return null;
      final ct = (response.headers['content-type'] ?? '').toLowerCase();
      if (ct.startsWith('video/') ||
          ct == 'application/mp4' ||
          ct == 'application/x-mpegurl') {
        return null; // サーバが直接動画を返した (単一解像度)
      }
      if (!ct.startsWith('text/') &&
          !ct.contains('html') &&
          !ct.contains('xml') &&
          ct.isNotEmpty) {
        return null;
      }
      return _probeHeightsFromHtml(response.body);
    } catch (_) {
      return null;
    }
  }

  static Set<int>? _probeHeightsFromHtml(String html) {
    final heights = <int>{};
    // 1) JS 埋め込み URL: 解像度ヒントを持つものだけ収集
    final embedded = _extractEmbeddedUrls(html);
    for (final r in embedded) {
      if (r.heightHint != null) heights.add(r.heightHint!);
    }
    // 2) <source> タグの src 属性から解像度キーワードを推定
    final sourceMatches = RegExp(
      r'''<source[^>]*\ssrc=["']([^"']+)["']''',
      caseSensitive: false,
    ).allMatches(html);
    for (final m in sourceMatches) {
      final src = m.group(1)!;
      final h = _guessHeight(src, '');
      if (h != null) heights.add(h);
    }
    // 3) og:video / twitter:player:stream 系 (単一 URL、解像度推定を試みる)
    for (final key in const [
      'og:video:secure_url',
      'og:video:url',
      'og:video',
    ]) {
      final v = _findMeta(html, 'property', key);
      if (v != null) {
        final h = _guessHeight(v, '');
        if (h != null) heights.add(h);
      }
    }
    // 検出できたのが 1 個以下 = 実質選択できないので null (=不明扱い) を返す
    if (heights.length < 2) return null;
    return heights;
  }

  static String _decodeHtmlEntities(String s) {
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x2F;', '/');
  }
}

class _Candidate {
  final String? raw;
  final String source;
  const _Candidate(this.raw, this.source);
}

class _RankedUrl {
  final String url;
  final int score;
  final int? heightHint;
  const _RankedUrl(this.url, this.score, {this.heightHint});
}
