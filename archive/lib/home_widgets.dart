import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'browser_session_provider.dart';
import 'home_tab_index_provider.dart';
import 'l10n/app_localizations.dart';
import 'offline_video_path.dart';
import 'mini_player_provider.dart';
import 'random_image_reload_provider.dart';
import 'smart_thumbnail.dart';
import 'theme_provider.dart';
import 'detail_page.dart';
import 'download_queue_provider.dart';
import 'thumbnail_setting_provider.dart';

/// ホーム画面に配置できるウィジェットの種類。
///
/// 識別子には enum の name を使って永続化するため、既存の name は変えないこと
/// (変えると保存済みのレイアウトが解決できなくなる)。
enum HomeWidgetKind {
  openTabs,
  continueWatching,
  randomPick,
  downloadProgress,
}

/// グリッドの列数。リストカードと同じ規約に合わせる。
/// 1 セルの目安幅。列数はこれを基準に決めるので、画面が広い端末 (iPad)
/// でも 1 セルの粒度は変わらない。
const double _kTargetCellWidth = 112;

/// 1 行の高さ。
/// 列幅に連動させると、列を細かくしたときに縦も潰れて中身が入らなくなる。
/// そのため列数とは独立に固定する。
const double _kRowHeight = 108;

/// グリッドの列数。
///
/// 下限 3 は 1×1 を左・中央・右に置けるようにするため。
/// 上限は iPad 横向き (約 1150dp) でも目安幅どおりの列数が取れる値にする。
/// ここを 8 等で抑えると iPad だけ 1 セルが大きくなり粒度が揃わない。
int homeGridColumns(double maxWidth) =>
    (maxWidth / _kTargetCellWidth).floor().clamp(3, 12);

/// 各アイテムの配置先 (列, 行) を左上から詰めて決める。
///
/// Wrap では高さの違う部品が並ぶと行の高さが最大に揃い、低い方の下に
/// 空きができていた。占有マスを持って実際に詰めることで隙間をなくす。
List<(int, int)> packHomeWidgetSlots(List<(int, int)> sizes, int cols) {
  final occupied = <List<bool>>[];
  void ensureRows(int upto) {
    while (occupied.length <= upto) {
      occupied.add(List<bool>.filled(cols, false));
    }
  }

  bool isFree(int c, int r, int w, int h) {
    for (var y = r; y < r + h; y++) {
      for (var x = c; x < c + w; x++) {
        if (occupied[y][x]) return false;
      }
    }
    return true;
  }

  final slots = <(int, int)>[];
  for (final (rawW, rawH) in sizes) {
    final w = rawW.clamp(1, cols);
    final h = rawH < 1 ? 1 : rawH;
    var placed = false;
    for (var r = 0; !placed; r++) {
      ensureRows(r + h - 1);
      for (var c = 0; c + w <= cols; c++) {
        if (!isFree(c, r, w, h)) continue;
        for (var y = r; y < r + h; y++) {
          for (var x = c; x < c + w; x++) {
            occupied[y][x] = true;
          }
        }
        slots.add((c, r));
        placed = true;
        break;
      }
    }
  }
  return slots;
}

/// 配置結果 [slots] を収めるのに必要な行数
int homeWidgetGridRows(List<(int, int)> slots, List<(int, int)> sizes) {
  var maxRow = 0;
  for (var i = 0; i < slots.length; i++) {
    final h = sizes[i].$2 < 1 ? 1 : sizes[i].$2;
    final bottom = slots[i].$2 + h;
    if (bottom > maxRow) maxRow = bottom;
  }
  return maxRow;
}

/// 配置された 1 件分。
///
/// [span] が幅、[rows] が高さ (それぞれグリッド何個分か)。
/// 将来「ウィジェットごとの設定」(表示するリストを選ぶ等) を足せるよう、
/// JSON のオブジェクト形式で保存しておく。
class HomeWidgetItem {
  final HomeWidgetKind kind;
  final int span;
  final int rows;

  const HomeWidgetItem(this.kind, {this.span = 2, this.rows = 1});

  Map<String, dynamic> toJson() =>
      {'kind': kind.name, 'w': span, 'h': rows};

  /// 保存値から復元する。
  /// 旧形式 (種類名だけの文字列) も受け付ける。
  static HomeWidgetItem? tryParse(String raw) {
    HomeWidgetKind? kindOf(String name) {
      for (final k in HomeWidgetKind.values) {
        if (k.name == name) return k;
      }
      return null;
    }

    // 新形式
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final kind = kindOf(decoded['kind']?.toString() ?? '');
        if (kind == null) return null;
        final w = (decoded['w'] as num?)?.toInt() ?? 2;
        // 'h' は高さを導入する前の保存値には無いので 1 とみなす
        final h = (decoded['h'] as num?)?.toInt() ?? 1;
        return HomeWidgetItem(
          kind,
          span: w < 1 ? 1 : w,
          rows: h < 1 ? 1 : h,
        );
      }
    } catch (_) {
      // 旧形式にフォールバック
    }

    // 旧形式 (種類名のみ)
    final kind = kindOf(raw);
    return kind == null ? null : HomeWidgetItem(kind);
  }
}

/// 既定で表示するウィジェット。
/// 空にしてある (何を置くかは利用者が FAB から選ぶ)。
const List<HomeWidgetItem> kDefaultHomeWidgets = [];

class HomeWidgetsNotifier extends StateNotifier<List<HomeWidgetItem>> {
  HomeWidgetsNotifier() : super(kDefaultHomeWidgets) {
    load();
  }

  /// 並びの永続化キー。
  /// saved_metadata とは独立させる。クラウド復元で作品データが丸ごと
  /// 上書きされる構造のため、同じ入れ物に置くとレイアウトまで巻き込まれる。
  static const _key = 'home_widgets_v1';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved == null) return; // 未設定なら既定のまま
    final restored = <HomeWidgetItem>[];
    for (final raw in saved) {
      final item = HomeWidgetItem.tryParse(raw);
      if (item != null) restored.add(item);
    }
    state = restored;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      state.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  bool contains(HomeWidgetKind kind) => state.any((e) => e.kind == kind);

  Future<void> add(HomeWidgetKind kind, {int span = 2, int rows = 1}) async {
    if (contains(kind)) return;
    state = [...state, HomeWidgetItem(kind, span: span, rows: rows)];
    await _save();
  }

  /// 並び順を入れ替える (カスタマイズモードのドラッグ用)
  Future<void> move(int from, int to) async {
    if (from == to) return;
    if (from < 0 || from >= state.length) return;
    if (to < 0 || to >= state.length) return;
    final next = [...state];
    next.insert(to, next.removeAt(from));
    state = next;
    await _save();
  }

  Future<void> remove(HomeWidgetKind kind) async {
    state = state.where((e) => e.kind != kind).toList();
    await _save();
  }

  Future<void> setSize(HomeWidgetKind kind, int span, int rows) async {
    state = [
      for (final e in state)
        if (e.kind == kind)
          HomeWidgetItem(e.kind, span: span, rows: rows)
        else
          e,
    ];
    await _save();
  }
}

final homeWidgetsProvider =
    StateNotifierProvider<HomeWidgetsNotifier, List<HomeWidgetItem>>(
  (ref) => HomeWidgetsNotifier(),
);

/// ウィジェットの表示名 (追加ウィンドウなどで使う)
String homeWidgetLabel(BuildContext context, HomeWidgetKind kind) {
  final l = L10n.of(context)!;
  switch (kind) {
    case HomeWidgetKind.openTabs:
      return l.home_widget_open_tabs;
    case HomeWidgetKind.continueWatching:
      return l.home_widget_continue;
    case HomeWidgetKind.randomPick:
      return l.home_widget_random;
    case HomeWidgetKind.downloadProgress:
      return l.home_widget_download;
  }
}

/// ウィジェットの 1 行説明 (追加ウィンドウで名前の下に出す)
String homeWidgetDescription(BuildContext context, HomeWidgetKind kind) {
  final l = L10n.of(context)!;
  switch (kind) {
    case HomeWidgetKind.openTabs:
      return l.home_widget_open_tabs_desc;
    case HomeWidgetKind.continueWatching:
      return l.home_widget_continue_desc;
    case HomeWidgetKind.randomPick:
      return l.home_widget_random_desc;
    case HomeWidgetKind.downloadProgress:
      return l.home_widget_download_desc;
  }
}

/// 種類ごとに選べるサイズ (幅, 高さ) の一覧。いずれもグリッド何個分か。
List<(int, int)> allowedSizesFor(HomeWidgetKind kind, int cols) {
  switch (kind) {
    // 1 件を大きく見せる作りなので、小さい 1×1 と大きい 2×2 の 2 択にする
    case HomeWidgetKind.continueWatching:
    case HomeWidgetKind.randomPick:
      return const [(1, 1), (2, 2)];
    // 1×1 は全体のみ、1×2 (縦長) はタスクごとの一覧を出す
    case HomeWidgetKind.downloadProgress:
      return const [(1, 1), (1, 2)];
    default:
      // 横スクロールで並べる種類は幅だけ選べる (高さは 1 固定)。
      //
      // 列数は端末幅で変わる (スマホ 3・iPad 8 など) ため、列数ぶん候補を
      // 並べると選択肢が増えすぎて選べない。
      // 「1 マス / 半分 / 全幅」の 3 段にまとめる。
      final widths = <int>{1, (cols / 2).round(), cols}.toList()..sort();
      return [for (final w in widths) (w, 1)];
  }
}

/// 保存値を許容サイズに丸める。
/// 許容外の組み合わせ (仕様変更前に保存されたもの等) は先頭の候補にする。
(int, int) resolveSize(HomeWidgetItem item, int cols) {
  final allowed = allowedSizesFor(item.kind, cols);
  for (final size in allowed) {
    if (size.$1 == item.span && size.$2 == item.rows) return size;
  }
  // 列数が変われば以前の幅が候補から外れる (別端末・グリッド粒度の変更)。
  // 先頭に落とすと設定が最小に戻ってしまうので、高さが一致する候補のうち
  // 幅が最も近いものへ寄せる。
  (int, int)? nearest;
  var best = 1 << 30;
  for (final size in allowed) {
    if (size.$2 != item.rows) continue;
    final diff = (size.$1 - item.span).abs();
    if (diff < best) {
      best = diff;
      nearest = size;
    }
  }
  return nearest ?? allowed.first;
}

/// ランダム表示の種。
///
/// アイテムの増減 (randomImageReloadProvider) と、ホーム画面を開いた回数
/// (homeVisitCounterProvider) の両方で変わる。build のたびに引き直すと
/// 再描画ごとに内容が入れ替わってちらつくため、契機をこの 2 つに限る。
int _randomSeed(WidgetRef ref) =>
    ref.watch(randomImageReloadProvider) * 1000 +
    ref.watch(homeVisitCounterProvider);

/// 実装済みのウィジェット。未実装のものは追加ウィンドウに出さない。
const Set<HomeWidgetKind> kImplementedHomeWidgets = {
  HomeWidgetKind.openTabs,
  HomeWidgetKind.continueWatching,
  HomeWidgetKind.randomPick,
  HomeWidgetKind.downloadProgress,
};

/// ホーム画面に並ぶウィジェット群。
class HomeWidgetsSection extends ConsumerStatefulWidget {
  /// 並べ替えモード中は削除ボタンを出す
  final bool editing;

  const HomeWidgetsSection({super.key, this.editing = false});

  @override
  ConsumerState<HomeWidgetsSection> createState() => _HomeWidgetsSectionState();
}

/// ホーム画面に並ぶウィジェット群。
///
/// 幅と高さをそれぞれグリッド何個分かで指定する。
/// GridView はセルごとの span を扱えず、reorderable_grid_view も均一セル
/// 前提なので、占有マスで実際に詰めてから Stack + AnimatedPositioned で描く。
/// これで隙間が出ず、並べ替え時も各カードが滑らかに移動する。
class _HomeWidgetsSectionState extends ConsumerState<HomeWidgetsSection> {
  /// 掴んでいるカードの *現在の* 位置。
  ///
  /// Draggable の data はドラッグ開始時に固定されるため、途中で並べ替えると
  /// 古い添字のままになる。2 マス以上動かしたときに移動元を誤るので、
  /// 入れ替えのたびにここを更新して参照する。
  int? _dragIndex;

  /// ドラッグ中に順序を入れ替える。
  ///
  /// ここで state を動かすと、他のカードが AnimatedPositioned で退くため
  /// リストの並べ替えと同じ体感になる。ヒットテストの最中に provider を
  /// 触らないよう microtask に逃がしている。
  void _reorderDuringDrag(int to) {
    final from = _dragIndex;
    if (from == null || from == to) return;
    _dragIndex = to;
    Future.microtask(() {
      if (!mounted) return;
      ref.read(homeWidgetsProvider.notifier).move(from, to);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(homeWidgetsProvider);
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cols = homeGridColumns(constraints.maxWidth);
        final cellW = (constraints.maxWidth - spacing * (cols - 1)) / cols;

        final sizes = [
          for (final item in items) resolveSize(item, cols),
        ];
        final slots = packHomeWidgetSlots(sizes, cols);
        final rows = homeWidgetGridRows(slots, sizes);
        final totalH = rows * _kRowHeight + (rows - 1) * spacing;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: SizedBox(
            height: totalH < 0 ? 0 : totalH,
            child: Stack(
              // カードの影はセル境界の外へ描かれる。既定の hardEdge だと
              // グリッド端の影が切れるため、はみ出しを許す。
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < items.length; i++)
                  AnimatedPositioned(
                    // 種類で同一性を保ち、順序が変わっても同じ子が移動する
                    key: ValueKey(items[i].kind),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: slots[i].$1 * (cellW + spacing),
                    top: slots[i].$2 * (_kRowHeight + spacing),
                    width: sizes[i].$1 * cellW + (sizes[i].$1 - 1) * spacing,
                    height: sizes[i].$2 * _kRowHeight +
                        (sizes[i].$2 - 1) * spacing,
                    child: _slot(
                      items,
                      i,
                      sizes[i].$1 * cellW + (sizes[i].$1 - 1) * spacing,
                      sizes[i].$2 * _kRowHeight + (sizes[i].$2 - 1) * spacing,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _slot(List<HomeWidgetItem> items, int index, double w, double h) {
    final item = items[index];

    Widget card({required bool showRemove}) => _HomeWidgetCard(
          item: item,
          editing: showRemove,
          onRemove: () =>
              ref.read(homeWidgetsProvider.notifier).remove(item.kind),
        );

    if (!widget.editing) return card(showRemove: false);

    return DragTarget<int>(
      onWillAcceptWithDetails: (d) {
        _reorderDuringDrag(index);
        return true;
      },
      builder: (context, candidate, rejected) {
        return LongPressDraggable<int>(
          // 受け手の型合わせ用。現在位置は _dragIndex を見る
          data: index,
          // 掴んだ指の位置にカードを合わせる
          dragAnchorStrategy: pointerDragAnchorStrategy,
          onDragStarted: () => _dragIndex = index,
          onDragEnd: (_) => _dragIndex = null,
          onDraggableCanceled: (_, __) => _dragIndex = null,
          feedback: _feedback(items, index, w, h),
          childWhenDragging: _dropPlaceholder(context),
          // 掴んでいる間は削除バッジを出さない (誤爆を避ける)
          child: card(showRemove: true),
        );
      },
    );
  }

  /// 指に追従する見た目。リストの並べ替えと同じく影を付けて浮かせる。
  ///
  /// 寸法は build() で計算済みの値を渡す。context.size はレイアウト前に
  /// null になり得るため、ここで参照すると制約が外れて崩れる。
  Widget _feedback(
      List<HomeWidgetItem> items, int index, double w, double h) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: w,
        height: h,
        child: Opacity(
          opacity: 0.95,
          child: _HomeWidgetCard(
            item: items[index],
            editing: false,
            onRemove: () {},
          ),
        ),
      ),
    );
  }

  /// ドラッグ中、元の位置に残す枠
  Widget _dropPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.onSurface.withValues(alpha: 0.04),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.18)),
      ),
    );
  }
}

/// 浮いて見えるカード。リストカードと同じ質感に揃える。
class _HomeWidgetCard extends StatelessWidget {
  final HomeWidgetItem item;
  final bool editing;
  final VoidCallback onRemove;

  const _HomeWidgetCard({
    required this.item,
    required this.editing,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.32),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: _content(context),
          ),
          if (editing)
            Positioned(
              top: 2,
              left: 2,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    switch (item.kind) {
      case HomeWidgetKind.openTabs:
        return const _OpenTabsContent();
      case HomeWidgetKind.continueWatching:
        return const _ContinueWatchingContent();
      case HomeWidgetKind.randomPick:
        return const _RandomPickContent();
      case HomeWidgetKind.downloadProgress:
        return const _DownloadProgressContent();
    }
  }
}

/// ② 開いているサイト — 今ブラウザで開いているページを横に並べる
///
/// 直近に見ていた 1 ページを openBrowserTabsProvider から取得して表示する。
/// provider が「アクティブタブを先頭」に並べているので、先頭を使えばよい。
/// ブラウザ側のタブ操作で即時に更新されるため、ホームが常時マウントされていても
/// 古い内容が残らない。
///
/// favicon は出さず、ページのタイトルを主役にする。
class _OpenTabsContent extends ConsumerWidget {
  const _OpenTabsContent();

  /// URL からホスト名を取り出す。取れない場合は URL をそのまま返す。
  static String _hostOf(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.isEmpty ? url : host;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final all = ref.watch(openBrowserTabsProvider);
    // 今いるタブは「ブラウザ」タブを押せば行けるので候補から除く。
    // (最新タブだけ出しても導線が重複するだけなので、他のタブを見せる)
    // ただし 1 件しか開いていない場合は除くと何も残らないため、その 1 件を出す。
    final others = all.where((t) => !t.isActive).toList();
    final candidates = others.isNotEmpty ? others : all;

    final header = Row(
      children: [
        Expanded(
          child: Text(
            l.home_widget_open_tabs,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        // 候補が複数あることを数字だけで示す (文言の翻訳が不要)
        if (candidates.length > 1)
          Text(
            '+${candidates.length - 1}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
      ],
    );

    if (candidates.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              l.home_widget_open_tabs_empty,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      );
    }

    // 抽選を build のたびに行うと、provider の更新や他の setState ごとに
    // カードが入れ替わってちらつく。既存のランダム画像ウィジェットと同じ
    // 再読込カウンタを種にすることで、同じ種・同じ候補数なら必ず同じ 1 件が
    // 選ばれ、カウンタが進んだときだけ引き直される。
    final seed = _randomSeed(ref);
    final tab = candidates[Random(seed).nextInt(candidates.length)];
    final title = tab.title.isNotEmpty ? tab.title : _hostOf(tab.url);
    // アプリ全体の「サムネイルを表示」設定を尊重する
    final showThumb = ref.watch(showThumbnailProvider);
    final hasImage = showThumb && tab.thumbnailUrl.isNotEmpty;
    // 画像が無いときは薄いプレースホルダなので、白文字では読めない
    final onImage = hasImage ? Colors.white : cs.onSurface;

    return GestureDetector(
      onTap: () => ref
          .read(browserSessionProvider.notifier)
          .requestOpen(tab.url, title: tab.title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    SmartThumbnail(
                      imageUrl: tab.thumbnailUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: isDark
                          ? const Color(0xFF2E2E2E)
                          : Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.public,
                        size: 28,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                  // 画像の上の文字を読めるように下部を暗くする
                  if (hasImage)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC000000)],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: onImage,
                          ),
                        ),
                        Text(
                          _hostOf(tab.url),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: onImage.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 「続きから見る」の 1 件分。
class _ContinueItem {
  final String url;
  final String title;
  final String? image;
  final Object? localVideoPath;
  final bool isAudioOnly;
  final int posSec;
  final int durSec;

  const _ContinueItem({
    required this.url,
    required this.title,
    required this.image,
    required this.localVideoPath,
    required this.isAudioOnly,
    required this.posSec,
    required this.durSec,
  });

  double get progress =>
      durSec > 0 ? (posSec / durSec).clamp(0.0, 1.0) : 0.0;
}

/// 再生位置が残っているオフライン作品を、最近見た順に返す。
///
/// 位置と長さだけでは並び順が決まらないため、プレイヤー側が
/// `offline_watched_at_<url>` に時刻を記録している。
final _continueWatchingProvider =
    FutureProvider<List<_ContinueItem>>((ref) async {
  // プレイヤーを閉じたときに進むカウンタ。これで読み直す
  ref.watch(continueWatchingReloadProvider);
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList('saved_metadata') ?? const <String>[];
  final rows = <({_ContinueItem item, int watchedAt})>[];
  for (final s in raw) {
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      final url = m['url']?.toString() ?? '';
      if (url.isEmpty) continue;
      final pos = prefs.getInt('offline_pos_$url');
      if (pos == null) continue; // 続きが残っていない
      // 実体が消えているアイテムは出さない (再生できないため)
      if (!OfflineVideoPaths.exists(m['localVideoPath'])) continue;
      rows.add((
        item: _ContinueItem(
          url: url,
          title: m['title']?.toString() ?? url,
          image: m['image']?.toString(),
          localVideoPath: m['localVideoPath'],
          isAudioOnly: m['isAudioOnly'] == true,
          posSec: pos,
          durSec: prefs.getInt('offline_dur_$url') ?? 0,
        ),
        watchedAt: prefs.getInt('offline_watched_at_$url') ?? 0,
      ));
    } catch (_) {}
  }
  rows.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
  return rows.map((e) => e.item).toList(growable: false);
});

/// ③ 続きから見る — 直近に見た 1 件を大きく出す。
/// 「開いているサイト」と同じ形式 (画像を敷いてタイトルを重ねる) に揃え、
/// 下端に視聴済みの割合をバーで示す。
class _ContinueWatchingContent extends ConsumerWidget {
  const _ContinueWatchingContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final items = ref.watch(_continueWatchingProvider).valueOrNull;

    Widget header(int count) => Row(
          children: [
            Expanded(
              child: Text(
                l.home_widget_continue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            // 他にも続きが残っている件数を数字だけで示す (翻訳不要)
            if (count > 1)
              Text(
                '+${count - 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
          ],
        );

    // 読み込み中は空表示を点滅させない
    if (items == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(0),
          const SizedBox(height: 6),
          const Expanded(child: SizedBox.shrink()),
        ],
      );
    }

    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(0),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              l.home_widget_continue_empty,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      );
    }

    final item = items.first;
    final image = item.image;
    final showThumb = ref.watch(showThumbnailProvider);
    final hasImage = showThumb && image != null && image.isNotEmpty;
    // プレースホルダは薄いので白文字では読めない
    final onImage = hasImage ? Colors.white : cs.onSurface;

    return GestureDetector(
      onTap: () {
        final path = OfflineVideoPaths.resolve(item.localVideoPath);
        if (path == null || path.isEmpty) return;
        ref.read(miniPlayerProvider.notifier).start(
              filePath: path,
              title: item.title,
              itemUrl: item.url,
              isAudioOnly: item.isAudioOnly,
              artworkUrl: image,
            );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(items.length),
          const SizedBox(height: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    SmartThumbnail(imageUrl: image, fit: BoxFit.cover)
                  else
                    Container(
                      color: isDark
                          ? const Color(0xFF2E2E2E)
                          : Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: Icon(
                        item.isAudioOnly
                            ? Icons.headphones
                            : Icons.movie_outlined,
                        size: 28,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                  // 画像の上の文字を読めるように下部を暗くする
                  if (hasImage)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC000000)],
                        ),
                      ),
                    ),
                  // 「続きから再生できる」ことを示す
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: onImage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 視聴済みの割合
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 3,
                      backgroundColor: Colors.black38,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ④ ランダム1件 — 保存済みアイテムから無作為に 1 件。
///
/// 抽選を build ごとに引くとちらつくため、既存のランダム画像と同じ
/// 再読込カウンタを種にする (同じ種なら必ず同じ 1 件が選ばれる)。
final _randomPickProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  // ホームを開くたびに引き直す (詳細は _randomSeed のコメント参照)
  // FutureProvider の Ref では型推論が効かず num になるため型引数を明示する
  final int seed = ref.watch<int>(randomImageReloadProvider) * 1000 +
      ref.watch<int>(homeVisitCounterProvider);
  // 「続きから見る」も配置されている場合、そちらが出す作品と被らせない。
  // 同じ作品が 2 つ並ぶと、せっかくの枠が 1 件分の情報しか運べなくなる。
  String? excludeUrl;
  final placed = ref.watch(homeWidgetsProvider);
  if (placed.any((e) => e.kind == HomeWidgetKind.continueWatching)) {
    final continueList = await ref.watch(_continueWatchingProvider.future);
    if (continueList.isNotEmpty) excludeUrl = continueList.first.url;
  }
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList('saved_metadata') ?? const <String>[];
  final items = <Map<String, dynamic>>[];
  for (final s in raw) {
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      if ((m['url']?.toString() ?? '').isEmpty) continue;
      items.add(m);
    } catch (_) {}
  }
  if (items.isEmpty) return null;
  var pool = items;
  if (excludeUrl != null) {
    final filtered =
        items.where((m) => m['url']?.toString() != excludeUrl).toList();
    // 除くと候補が無くなる場合は除外しない (空表示にしてしまわない)
    if (filtered.isNotEmpty) pool = filtered;
  }
  return pool[Random(seed).nextInt(pool.length)];
});

class _RandomPickContent extends ConsumerWidget {
  const _RandomPickContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final async = ref.watch(_randomPickProvider);
    final item = async.valueOrNull;

    final header = Text(
      l.home_widget_random,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
    );

    // 読み込み中は空表示を点滅させない
    if (async.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 6),
          const Expanded(child: SizedBox.shrink()),
        ],
      );
    }

    if (item == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              l.home_widget_random_empty,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      );
    }

    final image = item['image']?.toString();
    final showThumb = ref.watch(showThumbnailProvider);
    final hasImage = showThumb && image != null && image.isNotEmpty;
    final rawTitle = item['title']?.toString() ?? '';
    final title =
        rawTitle.isNotEmpty ? rawTitle : (item['url']?.toString() ?? '');
    final onImage = hasImage ? Colors.white : cs.onSurface;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailPage(
            listName: item['listName'],
            url: item['url'],
            title: item['title'],
            image: item['image'],
            cast: item['cast'] ?? '',
            genre: item['genre'] ?? '',
            series: item['series'] ?? '',
            label: item['label'] ?? '',
            maker: item['maker'] ?? '',
            rating: item['rating'],
            memo: item['memo'],
            isReadOnly: true,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    SmartThumbnail(imageUrl: image, fit: BoxFit.cover)
                  else
                    Container(
                      color: isDark
                          ? const Color(0xFF2E2E2E)
                          : Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.shuffle,
                        size: 26,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                  if (hasImage)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC000000)],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: onImage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// バイト数を読みやすい単位にする。単位記号は各言語共通なので翻訳不要。
String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  // 桁が小さいときだけ小数 1 桁まで出す (1.8 GB のように)
  final text = (v >= 100 || i == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return '$text ${units[i]}';
}

/// ダウンロード 1 件分の進捗行。
///
/// 行ごとにタイトルを添えるので凡例は不要。バーは単一色相で、
/// 値の大小で色を変えない (色だけで状態を伝えないため)。
class _TaskProgressRow extends StatelessWidget {
  final DownloadTask task;
  final Color trackColor;

  const _TaskProgressRow({required this.task, required this.trackColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final waiting = task.status == DownloadStatus.queued;
    final title = task.title.isNotEmpty ? task.title : task.itemUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                // 待機中は割合が無意味なので文言で示す
                waiting
                    ? L10n.of(context)!.download_status_queued
                    : '${(task.progress * 100).clamp(0, 100).round()}%',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              // 待機中は不確定ではなく 0 にする (動いていると誤解させない)
              value: waiting ? 0 : task.progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// ⑥ ダウンロード進行状況。
///
/// ボトムナビのリストアイコンが既に全体進捗を出しているため、ここで
/// 平均値のリングを 1 つ出しても重複するだけで情報が増えない。
/// そこで「どれがどこまで進んでいるか」を見せる方針にした。
/// 1×1 は全体の進捗バー、2×2 はタスクごとの行を並べる。
///
/// 進捗は毎チャンク通知されるので再ビルドが頻繁になるが、
/// 対象はこの小さな部分木だけなので許容する。
class _DownloadProgressContent extends ConsumerWidget {
  const _DownloadProgressContent();

  /// 失敗件数。色だけで状態を伝えないよう、アイコンと数値を必ず添える。
  Widget _failedRow(ColorScheme cs, L10n l, int count) {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 11, color: cs.error),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            '${l.download_status_failed} $count',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: cs.error),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final tasks = ref.watch(downloadQueueProvider);

    final active = tasks
        .where((t) =>
            t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.queued)
        .toList(growable: false);
    final failedCount =
        tasks.where((t) => t.status == DownloadStatus.failed).length;

    // トラック色はモードごとに明示的に選ぶ (自動反転にしない)
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.08);

    final header = Row(
      children: [
        Expanded(
          child: Text(
            l.home_widget_download,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        if (active.isNotEmpty)
          Text(
            // 件数は既存の "{length}件" を流用 (文言追加なし)
            l.grid_page_item_count(active.length),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
      ],
    );

    if (active.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.download_empty,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                if (failedCount > 0) ...[
                  const SizedBox(height: 6),
                  _failedRow(cs, l, failedCount),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // 受信済み / 全体。total が不明なタスクが混じると全体は出せない
    var received = 0;
    var total = 0;
    var totalKnown = true;
    for (final t in active) {
      received += t.received;
      final tt = t.total;
      if (tt == null || tt <= 0) {
        totalKnown = false;
      } else {
        total += tt;
      }
    }
    final overall = totalKnown && total > 0
        ? (received / total).clamp(0.0, 1.0)
        : active.fold<double>(0, (a, t) => a + t.progress) / active.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 背が高い (1×2) なら 1 件ずつ、1×1 なら全体だけを出す
              final detailed = constraints.maxHeight >= 150;
              if (!detailed) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(overall * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: overall,
                        minHeight: 4,
                        backgroundColor: trackColor,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(cs.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalKnown && total > 0
                          ? '${_formatBytes(received)} / ${_formatBytes(total)}'
                          : _formatBytes(received),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (failedCount > 0) _failedRow(cs, l, failedCount),
                  ],
                );
              }

              // 縦長: 入る件数だけ行を出し、残りは数字で示す
              const rowHeight = 27.0;
              var capacity = (constraints.maxHeight / rowHeight).floor();
              if (failedCount > 0) capacity -= 1;
              if (capacity < 1) capacity = 1;
              final shown =
                  active.length <= capacity ? active.length : capacity - 1;
              final hidden = active.length - shown;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final t in active.take(shown))
                    _TaskProgressRow(task: t, trackColor: trackColor),
                  if (hidden > 0)
                    Text(
                      '+$hidden',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  if (failedCount > 0) _failedRow(cs, l, failedCount),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ウィジェット追加ウィンドウ。
/// 追加済みのものはサイズ変更と削除、未追加のものは追加ができる。
Future<void> showAddHomeWidgetSheet(BuildContext context) async {
  final cs = Theme.of(context).colorScheme;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    // ホーム画面の背景と同じ色に揃える (他ページと同じ慣習)
    backgroundColor:
        cs.brightness == Brightness.dark ? cs.surface : kHomeSurfaceLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (bctx) => const _AddHomeWidgetSheet(),
  );
}

class _AddHomeWidgetSheet extends ConsumerWidget {
  const _AddHomeWidgetSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context)!;
    final items = ref.watch(homeWidgetsProvider);
    final maxH = MediaQuery.of(context).size.height * 0.75;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final cols = homeGridColumns(constraints.maxWidth);
              final cellW =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;
              // プレビューは実際の配置と同じ縦横比にする
              const cellH = _kRowHeight;

              // 種類ごとに 1 件だけ並べる。
              // サイズは各行のスイッチで切り替える (同じ種類が複数並ばない)。
              final kinds = <HomeWidgetKind>[
                for (final kind in HomeWidgetKind.values)
                  if (kImplementedHomeWidgets.contains(kind)) kind,
              ];

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.home_widget_add_title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final kind in kinds)
                            _GalleryEntry(
                              kind: kind,
                              sizes: allowedSizesFor(kind, cols),
                              cellW: cellW,
                              cellH: cellH,
                              spacing: spacing,
                              placed: items
                                  .where((e) => e.kind == kind)
                                  .firstOrNull,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ギャラリーの 1 件。
///
/// 1 種類につき 1 行。サイズはスイッチで切り替え、プレビューも連動させる。
/// プレビューはホーム画面と同じ寸法で**実際のウィジェットを描画**する。
/// モック画像を用意しないので、ウィジェット側を変更してもプレビューがずれない。
class _GalleryEntry extends ConsumerStatefulWidget {
  final HomeWidgetKind kind;
  final List<(int, int)> sizes;
  final double cellW;
  final double cellH;
  final double spacing;
  final HomeWidgetItem? placed;

  const _GalleryEntry({
    required this.kind,
    required this.sizes,
    required this.cellW,
    required this.cellH,
    required this.spacing,
    required this.placed,
  });

  @override
  ConsumerState<_GalleryEntry> createState() => _GalleryEntryState();
}

class _GalleryEntryState extends ConsumerState<_GalleryEntry> {
  /// 選択中のサイズ。
  ///
  /// 配置状態が変わるたびに初期化し直すと利用者の選択と喧嘩するので、
  /// 初回だけ「配置済みのサイズ」に合わせ、以降はこの行の状態として持つ。
  late (int, int) _selected;

  @override
  void initState() {
    super.initState();
    final placed = widget.placed;
    if (placed != null) {
      for (final size in widget.sizes) {
        if (size.$1 == placed.span && size.$2 == placed.rows) {
          _selected = size;
          return;
        }
      }
    }
    _selected = widget.sizes.first;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(homeWidgetsProvider.notifier);
    final placed = widget.placed;
    final (w, h) = _selected;
    final isCurrent =
        placed != null && placed.span == w && placed.rows == h;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 実物と同じ見た目のプレビュー。タップで配置 / サイズ変更 / 取り外し。
          GestureDetector(
            // 子を IgnorePointer にしているため、既定の deferToChild では
            // ヒットテストに応答する子がおらず onTap が発火しない。
            // カード全体で受け取るよう opaque を明示する。
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (isCurrent) {
                notifier.remove(widget.kind);
              } else if (placed != null) {
                notifier.setSize(widget.kind, w, h);
              } else {
                notifier.add(widget.kind, span: w, rows: h);
              }
            },
            child: SizedBox(
              width: widget.cellW * w + widget.spacing * (w - 1),
              height: widget.cellH * h + widget.spacing * (h - 1),
              child: IgnorePointer(
                // プレビュー内の操作は無効にし、タップは配置操作に使う
                child: _HomeWidgetCard(
                  item: HomeWidgetItem(widget.kind, span: w, rows: h),
                  editing: false,
                  onRemove: () {},
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  isCurrent ? Icons.check_circle : Icons.add_circle_outline,
                  size: 16,
                  color: isCurrent
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homeWidgetLabel(context, widget.kind),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      homeWidgetDescription(context, widget.kind),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // 選べるサイズが 1 つだけなら切り替えは出さない
              if (widget.sizes.length > 1) ...[
                const SizedBox(width: 8),
                _sizeSwitch(cs),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// サイズ切り替え。数字だけなので各言語の文言追加は不要。
  Widget _sizeSwitch(ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final size in widget.sizes)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selected = size),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: size == _selected ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: size == _selected
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '${size.$1}×${size.$2}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: size == _selected
                        ? Colors.white
                        : cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
