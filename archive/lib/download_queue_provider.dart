import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart' as bg;
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_video_path.dart';
import 'video_url_resolver.dart';

/// background_downloader 上でこのアプリのタスクを識別するグループ名。
///
/// 専用グループにコールバックを登録すると updates ストリームには流れないため、
/// 他の購読者と干渉しない。通知設定も
/// `configureNotificationForGroup` でこのグループを指定する必要がある
/// (既定グループ向けの `configureNotification` では適用されない)。
const String kOfflineDownloadGroup = 'archive_offline';

enum DownloadStatus { queued, downloading, completed, failed, canceled }

@immutable
class DownloadTask {
  final String id;
  final String url; // ソース URL (メディア直リンクを想定)
  final String title; // 表示用タイトル
  final String itemUrl; // saved_metadata 側の作品を紐付けるキー (=保存アイテムの url)
  final int? preferredHeight; // 希望解像度 (720 等) — resolver が候補選択に使用
  /// 音声アイテムとして保存するか。
  /// true の場合、ダウンロード完了後に映像トラックを捨てた .m4a へ変換し、
  /// saved_metadata に分類フラグを立てて UI と再生の扱いを音声にする。
  final bool audioOnly;
  final double progress; // 0.0 - 1.0
  final int received; // bytes
  final int? total; // bytes (unknown なら null)
  final DownloadStatus status;
  final String? error;
  final String? localPath;
  /// 「作品を新規保存 + DL」の一連の流れで開始されたかどうか。
  /// 失敗時の SnackBar に「URL はブックマークされました」を出すかの判定に使用。
  final bool wasFromNewSave;

  /// 署名付き URL の失効で自動再投入した回数。
  /// 同じ理由で無限に再投入しないよう上限判定に使う。
  final int autoRetries;

  /// 開始時の広告カウントから除外するか。
  ///
  /// クラウド復元後の一括再ダウンロードで使う。利用者の操作は「復元」の
  /// 1 回なのに、件数ぶんカウントが進んで途中で広告が何度も挟まるのを防ぐ。
  final bool suppressStartAd;

  const DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    required this.itemUrl,
    this.preferredHeight,
    this.audioOnly = false,
    this.progress = 0.0,
    this.received = 0,
    this.total,
    this.status = DownloadStatus.queued,
    this.error,
    this.localPath,
    this.wasFromNewSave = false,
    this.autoRetries = 0,
    this.suppressStartAd = false,
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
      audioOnly: audioOnly,
      progress: progress ?? this.progress,
      received: received ?? this.received,
      total: total ?? this.total,
      status: status ?? this.status,
      error: error ?? this.error,
      localPath: localPath ?? this.localPath,
      wasFromNewSave: wasFromNewSave,
      autoRetries: autoRetries,
      suppressStartAd: suppressStartAd,
    );
  }
}

class DownloadQueueNotifier extends StateNotifier<List<DownloadTask>> {
  DownloadQueueNotifier() : super(const []) {
    _registerCallbacks();
  }

  /// background_downloader 上でこのアプリのタスクを識別するグループ名。
  static const _group = kOfflineDownloadGroup;

  bool _callbacksRegistered = false;
  bool _notificationPermissionHandled = false;

  /// 通知権限を一度だけ確保する。
  ///
  /// Android 13 以降は権限が無いと進捗通知を出せず、通知が無いと
  /// priority 0 の UIDT が有効にならないため 9 分で打ち切られてしまう。
  /// 起動直後ではなくダウンロード開始時に要求することで、
  /// ユーザーにとって文脈のあるタイミングでダイアログが出る。
  /// 拒否された場合もダウンロード自体は継続する (通知が出ないだけ)。
  Future<void> _ensureNotificationPermission() async {
    if (_notificationPermissionHandled) return;
    _notificationPermissionHandled = true;
    try {
      final permissions = bg.FileDownloader().permissions;
      final current = await permissions.status(bg.PermissionType.notifications);
      // 未決定のときだけ要求する。
      // 既に拒否されている場合は OS が再表示しないため要求しない。
      if (current == bg.PermissionStatus.undetermined) {
        await permissions.request(bg.PermissionType.notifications);
      }
    } catch (_) {
      // 権限まわりで失敗してもダウンロードは止めない
    }
  }

  void _registerCallbacks() {
    if (_callbacksRegistered) return;
    _callbacksRegistered = true;
    bg.FileDownloader().registerCallbacks(
      group: _group,
      taskStatusCallback: _onStatus,
      taskProgressCallback: _onProgress,
    );
  }

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
    bool audioOnly = false,
    bool wasFromNewSave = false,
    bool suppressStartAd = false,
  }) async {
    // 既に active なタスクと重複する場合は開始しない。
    // itemUrl だけで見ていると、同じページを別アイテムとして保存した場合に
    // 同一動画が二重にダウンロードされ、参照の無いファイルが残ってしまう。
    // (実測で 5 ミリ秒差の二重投入により 47MB のファイルが 2 つ残っていた)
    if (state.any(
      (t) =>
          (t.itemUrl == itemUrl || t.url == url) &&
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
      audioOnly: audioOnly,
      status: DownloadStatus.queued,
      wasFromNewSave: wasFromNewSave,
      suppressStartAd: suppressStartAd,
    );
    state = [...state, task];
    // 別マイクロタスクで実行 (呼び出し元は即帰る)
    unawaited(_enqueue(task));
  }

  /// 進捗コールバック。パッケージ側は 0.0〜1.0 の progress と
  /// expectedFileSize (不明なら -1) を返す。
  void _onProgress(bg.TaskProgressUpdate update) {
    final id = update.task.taskId;
    final total =
        update.expectedFileSize > 0 ? update.expectedFileSize : null;
    final progress = update.progress.clamp(0.0, 1.0).toDouble();
    _updateTask(
      id,
      progress: progress,
      total: total,
      received: total != null ? (total * progress).round() : null,
    );
  }

  /// 状態コールバック。パッケージの TaskStatus を自前の DownloadStatus に写す。
  Future<void> _onStatus(bg.TaskStatusUpdate update) async {
    final id = update.task.taskId;
    // 回線速度で成否が変わる不具合の切り分け用。
    // Android の 9 分制限なら約 9 分後に paused / failed が現れる。
    // 署名付き URL の期限切れなら、もっと早くサーバ由来の例外が出る。
    switch (update.status) {
      case bg.TaskStatus.enqueued:
      case bg.TaskStatus.waitingToRetry:
        _updateTask(id, status: DownloadStatus.queued);
        return;
      case bg.TaskStatus.running:
        _updateTask(id, status: DownloadStatus.downloading);
        return;
      case bg.TaskStatus.paused:
        // 一時停止は自動再開されるため、UI 上は継続中として扱う
        _updateTask(id, status: DownloadStatus.downloading);
        return;
      case bg.TaskStatus.canceled:
        _updateTask(id, status: DownloadStatus.canceled);
        return;
      case bg.TaskStatus.notFound:
        _updateTask(id, status: DownloadStatus.failed, error: 'HTTP 404');
        return;
      case bg.TaskStatus.failed:
        final desc = update.exception?.description ?? 'DOWNLOAD_FAILED';
        // 署名付き URL が失効すると、CDN は動画ではなく HTML のエラーページを
        // 返す (CDN77 では HTTP 410 Gone)。同じ URL で再試行しても無意味なので、
        // ページ URL から署名を取り直して再投入する。
        if (_isRetriableDownloadFailure(desc) &&
            await _retryWithFreshUrl(update)) {
          return;
        }
        _updateTask(id, status: DownloadStatus.failed, error: desc);
        return;
      case bg.TaskStatus.complete:
        await _onComplete(update);
        return;
    }
  }

  Future<void> _onComplete(bg.TaskStatusUpdate update) async {
    final id = update.task.taskId;
    final path = await update.task.filePath();
    final file = File(path);

    // ページ URL を掴んでしまった場合、HTML がそのまま保存される。
    // ストリーミング時に弾いていた判定を、Content-Type 由来の mimeType で代替する。
    final mime = update.mimeType ?? '';
    if (!_looksLikeVideoResponse(mime, update.task.url)) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
      // タスクのエラー文字列は UI にしか出ないため、切り分け用にログも残す
      _updateTask(id,
          status: DownloadStatus.failed, error: 'NOT_DIRECT_VIDEO_URL');
      return;
    }

    // metaData に載せた付帯情報を復元する
    var itemUrl = '';
    var audioOnly = false;
    int? preferredHeight;
    try {
      final meta = jsonDecode(update.task.metaData) as Map<String, dynamic>;
      itemUrl = meta['itemUrl']?.toString() ?? '';
      audioOnly = meta['audioOnly'] == true;
      preferredHeight = (meta['preferredHeight'] as num?)?.toInt();
    } catch (_) {}

    // 音声のみ指定の場合、ここで映像トラックを捨てた音声ファイルへ変換する。
    // 変換に失敗したときは元の動画ファイルをそのまま採用し、
    // 「ダウンロードは成功したのに何も残らない」状態を避ける。
    var finalPath = path;
    if (audioOnly) {
      final converted = await _convertToAudioOnly(file);
      if (converted == null) {
        // 音声トラックが無い (プレビュー動画を掴んだ等)。
        // 動画のまま残すと「音声のみで保存したはずの数秒動画」になり、
        // 利用者から見れば壊れたアイテムなので、消して明示的に失敗させる。
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}
        _updateTask(id,
            status: DownloadStatus.failed, error: 'AUDIO_EXTRACT_FAILED');
        return;
      }
      finalPath = converted.path;
    }

    int size = 0;
    try {
      size = await File(finalPath).length();
    } catch (_) {}

    if (itemUrl.isNotEmpty) {
      await _persistLocalPath(
        itemUrl: itemUrl,
        localPath: finalPath,
        size: size,
        audioOnly: audioOnly,
        preferredHeight: preferredHeight,
      );
    }
    _updateTask(id,
        status: DownloadStatus.completed, progress: 1.0, localPath: finalPath);
  }

  /// 映像トラックを捨てて音声のみのファイル (.m4a) を作る。
  ///
  /// まず再エンコードなしの stream copy を試す。数秒で終わり音質も劣化しない。
  /// webm/mkv の Opus/Vorbis は MP4 コンテナへそのままでは入らないため、
  /// copy が失敗したときだけ AAC へ再エンコードする。
  /// 成功したら元の動画ファイルを削除して容量を解放する
  /// (容量削減が「音声のみ」保存の目的なので、残したままでは意味がない)。
  ///
  /// 失敗時は null を返し、呼び出し側は元の動画ファイルを使い続ける。
  Future<File?> _convertToAudioOnly(File source) async {
    try {
      if (!await source.exists()) return null;
    } catch (_) {
      return null;
    }

    final out = File(p.join(p.dirname(source.path),
        '${p.basenameWithoutExtension(source.path)}.m4a'));
    // 入力が既に .m4a の場合は変換不要 (出力先が入力と同一になる)
    if (out.path == source.path) return source;

    Future<bool> attempt(List<String> args) async {
      try {
        if (await out.exists()) await out.delete();
      } catch (_) {}
      try {
        // 文字列版 execute() は空白で引数を分割するため、
        // パスをそのまま安全に渡せる executeWithArguments を使う。
        final session = await FFmpegKit.executeWithArguments(args);
        final rc = await session.getReturnCode();
        if (!ReturnCode.isSuccess(rc)) {
          // 失敗理由を残す。これが無いと「ffmpeg が動いていない」のか
          // 「音声トラックが無い」のかを実機で切り分けられない。
          return false;
        }
      } catch (_) {
        // getReturnCode は Future.error を返すことがあるため捕捉する。
        // プラグイン未登録などもここに来る。
        return false;
      }
      try {
        return await out.exists() && await out.length() > 0;
      } catch (_) {
        return false;
      }
    }

    // -y: 既存出力を上書き / -vn: 映像を除去 / -map a: 音声トラックのみ対象
    final ok = await attempt(
          ['-y', '-i', source.path, '-vn', '-map', 'a', '-c:a', 'copy', out.path],
        ) ||
        await attempt([
          '-y',
          '-i',
          source.path,
          '-vn',
          '-map',
          'a',
          '-c:a',
          'aac',
          '-b:a',
          '192k',
          out.path,
        ]);

    if (!ok) {
      try {
        if (await out.exists()) await out.delete();
      } catch (_) {}
      return null;
    }

    try {
      if (await source.exists()) await source.delete();
    } catch (_) {}
    return out;
  }

  /// background_downloader にタスクを投入する。
  ///
  /// URL 解決と HLS 判定は従来どおり Dart 側で先に行い、実際の通信は
  /// ネイティブ (iOS: URLSession background / Android: 専用サービス) に
  /// 委ねることで、アプリがバックグラウンドでもダウンロードが継続する。
  Future<void> _enqueue(DownloadTask initial) async {
    try {
      // 通知が出ないと Android の UIDT が効かず 9 分で打ち切られるため、
      // 投入前に権限を確保しておく (拒否されても続行する)
      await _ensureNotificationPermission();

      // ページ URL の場合はまず HTML から動画直リンクを解決
      String sourceUrl = initial.url;
      if (!VideoUrlResolver.looksLikeDirectVideo(sourceUrl)) {
        final resolved = await VideoUrlResolver.resolve(
          sourceUrl,
          preferredHeight: initial.preferredHeight,
        );
        // どの戦略でどの URL を選んだかを残す。これが無いと
        // 「短いプレビューを掴んでいる」ことを実機で特定できない。
        if (resolved != null) {
          sourceUrl = resolved.url;
        }
      } else {
      }
      // HLS (.m3u8) は現状未対応 (ffmpeg 経由の変換が必要)
      final lowerPath = (Uri.tryParse(sourceUrl)?.path ?? '').toLowerCase();
      if (lowerPath.endsWith('.m3u8')) {
        _updateTask(initial.id,
            status: DownloadStatus.failed, error: 'HLS_NOT_SUPPORTED');
        return;
      }

      // 一部の動画 CDN はブラウザ相当の UA と Referer を要求する (xvideos 等)
      final headers = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15',
        'Accept': '*/*',
      };
      if (initial.itemUrl.isNotEmpty && initial.itemUrl != sourceUrl) {
        try {
          final refUri = Uri.parse(initial.itemUrl);
          headers['Referer'] = initial.itemUrl;
          headers['Origin'] = '${refUri.scheme}://${refUri.host}';
        } catch (_) {}
      }

      final ext = _extensionForUrl(sourceUrl);
      final task = bg.DownloadTask(
        // 自前の id をそのまま taskId にして両者を一致させる
        taskId: initial.id,
        url: sourceUrl,
        headers: headers,
        filename: '${initial.id}$ext',
        // OfflineVideoPaths と同じ場所に保存し、解決処理と確実に一致させる
        directory: OfflineVideoPaths.dirName,
        baseDirectory: bg.BaseDirectory.applicationDocuments,
        group: _group,
        updates: bg.Updates.statusAndProgress,
        // Android の既定 9 分タイムアウト対策:
        // allowPause で一時停止→自動再開、priority 0 で UIDT を使う
        allowPause: true,
        priority: 0,
        // 完了コールバックは別経路で来るため、必要な情報を持たせておく
        metaData: jsonEncode({
          'itemUrl': initial.itemUrl,
          'audioOnly': initial.audioOnly,
          // アプリ再起動後に DB から復活したタスクでも、画質指定と
          // 自動再投入回数を失わないように持たせておく
          'preferredHeight': initial.preferredHeight,
          'autoRetries': initial.autoRetries,
        }),
      );

      final accepted = await bg.FileDownloader().enqueue(task);
      if (!accepted) {
        _updateTask(initial.id,
            status: DownloadStatus.failed, error: 'ENQUEUE_FAILED');
      }
    } catch (e) {
      _updateTask(initial.id,
          status: DownloadStatus.failed, error: e.toString());
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
    if (task.status == DownloadStatus.downloading ||
        task.status == DownloadStatus.queued) {
      unawaited(bg.FileDownloader().cancelTaskWithId(id));
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

  /// 署名付き URL の失効による自動再投入の上限。
  /// 再解決してもなお失敗する場合は、別の原因なので諦めてユーザーに見せる。
  static const _maxAutoRetries = 2;

  /// 署名を取り直して再投入する価値のある失敗かどうか。
  ///
  /// - レスポンスが HTML: 署名付き URL が失効し、CDN が動画の代わりに
  ///   エラーページ (CDN77 では HTTP 410 Gone) を返している
  /// - ソケット切断系: モバイル回線での実測で
  ///   `SocketException: Software caused connection abort` が出た。
  ///   一時的な切断なので、取り直して再開する価値がある
  ///
  /// 恒久的な失敗 (404 等) で無駄に繰り返さないよう、呼び出し側で
  /// [_maxAutoRetries] による上限を掛けている。
  bool _isRetriableDownloadFailure(String error) {
    final e = error.toLowerCase();
    if (e.contains('<!doctype html') || e.contains('<html')) return true;
    return e.contains('socketexception') ||
        e.contains('connection abort') ||
        e.contains('connection reset') ||
        e.contains('connection closed') ||
        e.contains('timed out') ||
        e.contains('timeout');
  }

  /// ページ URL から署名を取り直して再投入する。
  ///
  /// [_enqueue] は直リンクでない URL を毎回 VideoUrlResolver で解決するため、
  /// 同じタスクを作り直すだけで新しい署名が得られる。
  /// 再投入したら true、できない場合 (元が直リンク / 上限到達) は false。
  Future<bool> _retryWithFreshUrl(bg.TaskStatusUpdate update) async {
    final id = update.task.taskId;
    final idx = state.indexWhere((t) => t.id == id);
    // アプリ再起動後は自前のキューが空になっており、パッケージの DB から
    // 復活したタスクだけが失敗してくる。その場合は metaData から復元する。
    final DownloadTask old;
    if (idx >= 0) {
      old = state[idx];
    } else {
      final restored = _taskFromMetaData(update);
      if (restored == null) return false;
      old = restored;
    }
    // 元から直リンク指定の場合、再解決しても同じ URL になるので諦める
    if (VideoUrlResolver.looksLikeDirectVideo(old.url)) return false;
    if (old.autoRetries >= _maxAutoRetries) return false;
    final task = DownloadTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      url: old.url,
      title: old.title,
      itemUrl: old.itemUrl,
      preferredHeight: old.preferredHeight,
      audioOnly: old.audioOnly,
      wasFromNewSave: old.wasFromNewSave,
      status: DownloadStatus.queued,
      autoRetries: old.autoRetries + 1,
      suppressStartAd: old.suppressStartAd,
    );
    state = [
      for (final t in state)
        if (t.id != id) t,
      task,
    ];
    unawaited(_enqueue(task));
    return true;
  }

  /// 失敗した native タスクの metaData から自前のタスクを復元する。
  ///
  /// url にはページ URL (itemUrl) を入れる。失効した CDN URL をそのまま
  /// 使い回しても無意味で、ページから署名を取り直す必要があるため。
  DownloadTask? _taskFromMetaData(bg.TaskStatusUpdate update) {
    try {
      final meta = jsonDecode(update.task.metaData) as Map<String, dynamic>;
      final itemUrl = meta['itemUrl']?.toString() ?? '';
      if (itemUrl.isEmpty) return null;
      return DownloadTask(
        id: update.task.taskId,
        url: itemUrl,
        title: itemUrl,
        itemUrl: itemUrl,
        preferredHeight: (meta['preferredHeight'] as num?)?.toInt(),
        audioOnly: meta['audioOnly'] == true,
        autoRetries: (meta['autoRetries'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
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
      // 再試行でも元の指定を引き継ぐ。
      // 引き継がないと「音声のみ」で失敗した DL が動画扱いで再実行される。
      audioOnly: old.audioOnly,
      wasFromNewSave: old.wasFromNewSave,
      status: DownloadStatus.queued,
    );
    // 古い失敗タスクを消して新しいタスクを追加
    state = [
      for (final t in state)
        if (t.id != id) t,
      task,
    ];
    unawaited(_enqueue(task));
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
    bool audioOnly = false,
    int? preferredHeight,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_metadata') ?? [];
    final updated = list.map((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        if (map['url'] == itemUrl) {
          // 絶対パスではなくファイル名のみを保存する。
          // iOS はアプリ更新でコンテナ UUID が変わるため、絶対パスだと
          // 更新後に参照が切れて「未ダウンロード」扱いになる。
          map['localVideoPath'] = OfflineVideoPaths.toStored(localPath);
          map['localVideoSize'] = size;
          map['localVideoDownloadedAt'] =
              DateTime.now().toIso8601String();
          // 音声アイテムとしての分類フラグ。
          // 実体は _convertToAudioOnly で音声のみのファイルへ変換済み。
          if (audioOnly) {
            map['isAudioOnly'] = true;
          } else {
            map.remove('isAudioOnly');
          }
          // 選んだ画質。クラウド復元後の再ダウンロードで同じ画質を使う。
          // 無指定 (最高画質) のときは残さない。
          if (preferredHeight != null) {
            map['offlineHeight'] = preferredHeight;
          } else {
            map.remove('offlineHeight');
          }
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
