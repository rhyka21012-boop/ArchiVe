import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'video_url_resolver.dart';

enum DownloadStatus { queued, downloading, completed, failed, canceled }

@immutable
class DownloadTask {
  final String id;
  final String url; // ソース URL (メディア直リンクを想定)
  final String title; // 表示用タイトル
  final String itemUrl; // saved_metadata 側の作品を紐付けるキー (=保存アイテムの url)
  final int? preferredHeight; // 希望解像度 (720 等) — resolver が候補選択に使用
  final double progress; // 0.0 - 1.0
  final int received; // bytes
  final int? total; // bytes (unknown なら null)
  final DownloadStatus status;
  final String? error;
  final String? localPath;
  /// 「作品を新規保存 + DL」の一連の流れで開始されたかどうか。
  /// 失敗時の SnackBar に「URL はブックマークされました」を出すかの判定に使用。
  final bool wasFromNewSave;

  const DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    required this.itemUrl,
    this.preferredHeight,
    this.progress = 0.0,
    this.received = 0,
    this.total,
    this.status = DownloadStatus.queued,
    this.error,
    this.localPath,
    this.wasFromNewSave = false,
  });

  DownloadTask copyWith({
    double? progress,
    int? received,
    int? total,
    DownloadStatus? status,
    String? error,
    String? localPath,
  }) {
    return DownloadTask(
      id: id,
      url: url,
      title: title,
      itemUrl: itemUrl,
      preferredHeight: preferredHeight,
      progress: progress ?? this.progress,
      received: received ?? this.received,
      total: total ?? this.total,
      status: status ?? this.status,
      error: error ?? this.error,
      localPath: localPath ?? this.localPath,
      wasFromNewSave: wasFromNewSave,
    );
  }
}

class DownloadQueueNotifier extends StateNotifier<List<DownloadTask>> {
  DownloadQueueNotifier() : super(const []);

  final Map<String, http.Client> _clients = {};

  bool get hasActive => state.any(
        (t) =>
            t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.queued,
      );

  int get activeCount => state
      .where(
        (t) =>
            t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.queued,
      )
      .length;

  /// 進行中の平均進捗 (progress FAB 表示用)
  double get averageActiveProgress {
    final active = state.where(
      (t) =>
          t.status == DownloadStatus.downloading ||
          t.status == DownloadStatus.queued,
    );
    if (active.isEmpty) return 0.0;
    final sum = active.fold<double>(0.0, (a, t) => a + t.progress);
    return sum / active.length;
  }

  /// 新規タスクを追加してダウンロード開始
  Future<void> start({
    required String url,
    required String title,
    required String itemUrl,
    int? preferredHeight,
    bool wasFromNewSave = false,
  }) async {
    // 同一 itemUrl で既に active なタスクがあれば重複開始しない
    if (state.any(
      (t) =>
          t.itemUrl == itemUrl &&
          (t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.queued),
    )) {
      return;
    }
    final task = DownloadTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      url: url,
      title: title,
      itemUrl: itemUrl,
      preferredHeight: preferredHeight,
      status: DownloadStatus.queued,
      wasFromNewSave: wasFromNewSave,
    );
    state = [...state, task];
    // 別マイクロタスクで実行 (呼び出し元は即帰る)
    unawaited(_run(task));
  }

  Future<void> _run(DownloadTask initial) async {
    _updateTask(initial.id,
        status: DownloadStatus.downloading, progress: 0.0);
    final client = http.Client();
    _clients[initial.id] = client;
    try {
      // ページ URL の場合はまず HTML から動画直リンクを解決
      String sourceUrl = initial.url;
      if (!VideoUrlResolver.looksLikeDirectVideo(sourceUrl)) {
        final resolved = await VideoUrlResolver.resolve(
          sourceUrl,
          preferredHeight: initial.preferredHeight,
        );
        if (resolved != null) {
          sourceUrl = resolved.url;
        }
      }
      // HLS (.m3u8) は現状未対応 (Phase 2 で ffmpeg 経由の変換を予定)
      final lowerPath = (Uri.tryParse(sourceUrl)?.path ?? '').toLowerCase();
      if (lowerPath.endsWith('.m3u8')) {
        _updateTask(initial.id,
            status: DownloadStatus.failed, error: 'HLS_NOT_SUPPORTED');
        return;
      }
      final request = http.Request('GET', Uri.parse(sourceUrl));
      // 一部の動画 CDN はブラウザ相当の UA と Referer を要求する (xvideos 等)
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15';
      request.headers['Accept'] = '*/*';
      if (initial.itemUrl.isNotEmpty && initial.itemUrl != sourceUrl) {
        try {
          final refUri = Uri.parse(initial.itemUrl);
          request.headers['Referer'] = initial.itemUrl;
          request.headers['Origin'] = '${refUri.scheme}://${refUri.host}';
        } catch (_) {}
      }
      final response = await client.send(request);
      if (response.statusCode >= 400) {
        _updateTask(initial.id,
            status: DownloadStatus.failed,
            error: 'HTTP ${response.statusCode}');
        return;
      }
      // Content-Type チェック: YouTube 等のページ URL (text/html) を弾く
      final contentType =
          (response.headers['content-type'] ?? '').toLowerCase();
      if (!_looksLikeVideoResponse(contentType, initial.url)) {
        _updateTask(initial.id,
            status: DownloadStatus.failed,
            error: 'NOT_DIRECT_VIDEO_URL');
        return;
      }
      final total = response.contentLength;
      final ext = _extensionForUrl(sourceUrl);
      final dir = await getApplicationDocumentsDirectory();
      final saveDir = Directory(p.join(dir.path, 'offline_videos'));
      if (!await saveDir.exists()) await saveDir.create(recursive: true);
      final file = File(p.join(saveDir.path, '${initial.id}$ext'));
      final sink = file.openWrite();
      int received = 0;
      final completer = Completer<void>();
      late StreamSubscription<List<int>> sub;
      sub = response.stream.listen(
        (chunk) {
          sink.add(chunk);
          received += chunk.length;
          final progress = total != null && total > 0
              ? (received / total).clamp(0.0, 1.0)
              : 0.0;
          _updateTask(initial.id,
              received: received, total: total, progress: progress);
        },
        onDone: () async {
          await sink.close();
          completer.complete();
        },
        onError: (e) async {
          await sink.close();
          completer.completeError(e);
        },
        cancelOnError: true,
      );
      // キャンセル用: state から消えたら sub.cancel
      // (キャンセル時は client.close で stream が中断される)
      await completer.future;
      await sub.cancel();

      // 完了: リスナーが completed 状態でキャッシュ更新するので、
      // 先に prefs へ localVideoPath を書き込んでから state を切り替える
      await _persistLocalPath(
        itemUrl: initial.itemUrl,
        localPath: file.path,
        size: await file.length(),
      );
      _updateTask(initial.id,
          status: DownloadStatus.completed,
          progress: 1.0,
          localPath: file.path);
    } catch (e) {
      _updateTask(initial.id,
          status: DownloadStatus.failed, error: e.toString());
    } finally {
      _clients.remove(initial.id);
      client.close();
    }
  }

  /// タスクをキャンセルまたは完了/失敗タスクを一覧から除去
  void cancel(String id) {
    final task = state.firstWhere(
      (t) => t.id == id,
      orElse: () => DownloadTask(
        id: '',
        url: '',
        title: '',
        itemUrl: '',
      ),
    );
    if (task.id.isEmpty) return;
    if (task.status == DownloadStatus.downloading) {
      _clients[id]?.close();
      _updateTask(id, status: DownloadStatus.canceled);
    }
    state = state.where((t) => t.id != id).toList();
  }

  /// 指定 itemUrl の完了タスクだけを一覧から除去 (削除時に使用)
  void clearCompletedForItem(String itemUrl) {
    state = state
        .where((t) => !(t.itemUrl == itemUrl &&
            t.status == DownloadStatus.completed))
        .toList();
  }

  /// 失敗タスクをキュー投入時と同じ設定で再実行
  Future<void> retry(String id) async {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final old = state[idx];
    if (old.status != DownloadStatus.failed &&
        old.status != DownloadStatus.canceled) return;
    // 新規タスクとして再投入
    final task = DownloadTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      url: old.url,
      title: old.title,
      itemUrl: old.itemUrl,
      preferredHeight: old.preferredHeight,
      status: DownloadStatus.queued,
    );
    // 古い失敗タスクを消して新しいタスクを追加
    state = [
      for (final t in state)
        if (t.id != id) t,
      task,
    ];
    unawaited(_run(task));
  }

  /// 完了/失敗タスクをすべて一覧から除去
  void clearFinished() {
    state = state
        .where((t) =>
            t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.queued)
        .toList();
  }

  void _updateTask(
    String id, {
    DownloadStatus? status,
    double? progress,
    int? received,
    int? total,
    String? error,
    String? localPath,
  }) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(
            status: status,
            progress: progress,
            received: received,
            total: total,
            error: error,
            localPath: localPath,
          )
        else
          t,
    ];
  }

  /// レスポンスが動画ファイルらしいかを判定する。
  /// - Content-Type が video/* または application/octet-stream → OK
  /// - Content-Type が text/*, application/json/xml/xhtml → NG (ページ URL)
  /// - Content-Type 不明で URL パスの拡張子が動画拡張子 → OK
  /// - 上記いずれでもない場合は URL 拡張子で判定
  bool _looksLikeVideoResponse(String contentType, String url) {
    final ct = contentType.split(';').first.trim();
    if (ct.startsWith('video/')) return true;
    if (ct == 'application/octet-stream') return true;
    if (ct == 'application/mp4' || ct == 'application/x-mpegurl') return true;
    if (ct.startsWith('text/') ||
        ct == 'application/json' ||
        ct == 'application/xml' ||
        ct == 'application/xhtml+xml') {
      return false;
    }
    // Content-Type 判定できないとき: URL パス拡張子でフォールバック
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    const allowed = {'.mp4', '.m4v', '.mov', '.webm', '.mkv'};
    return allowed.any(path.endsWith);
  }

  String _extensionForUrl(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final ext = p.extension(path).toLowerCase();
    const allowed = {'.mp4', '.m4v', '.mov', '.webm', '.mkv'};
    return allowed.contains(ext) ? ext : '.mp4';
  }

  /// saved_metadata に localVideoPath 等を書き込み
  Future<void> _persistLocalPath({
    required String itemUrl,
    required String localPath,
    required int size,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_metadata') ?? [];
    final updated = list.map((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        if (map['url'] == itemUrl) {
          map['localVideoPath'] = localPath;
          map['localVideoSize'] = size;
          map['localVideoDownloadedAt'] =
              DateTime.now().toIso8601String();
        }
        return jsonEncode(map);
      } catch (_) {
        return s;
      }
    }).toList();
    await prefs.setStringList('saved_metadata', updated);
  }
}

final downloadQueueProvider =
    StateNotifierProvider<DownloadQueueNotifier, List<DownloadTask>>((ref) {
  return DownloadQueueNotifier();
});
