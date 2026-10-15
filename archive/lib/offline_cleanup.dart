import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_video_path.dart';

/// 作品アイテム / リスト削除時に、対応するオフライン動画ファイルと
/// 前回再生位置/長さ等の prefs を一括で削除するヘルパ。
class OfflineCleanup {
  /// 与えられた URL 一覧に紐づくオフラインファイル・prefs を削除する。
  /// saved_metadata が更新される **前** に呼ぶこと (localVideoPath の参照が
  /// まだメタデータに残っているうちに削除するため)。
  static Future<void> forUrls(Iterable<String> urls) async {
    final urlSet = urls.toSet();
    if (urlSet.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_metadata') ?? [];
    for (final s in list) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final url = map['url']?.toString();
        if (url == null || !urlSet.contains(url)) continue;

        // オフライン動画ファイルを削除
        // 保存値はファイル名のみなので、現在のディレクトリと結合して解決する
        final f = OfflineVideoPaths.fileFor(map['localVideoPath']);
        if (f != null) {
          try {
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }

        // 前回再生位置 / 動画長さの prefs も削除
        await prefs.remove('offline_pos_$url');
        await prefs.remove('offline_dur_$url');
      } catch (_) {}
    }
  }

  /// saved_metadata から参照されていないオフラインファイルを削除する。
  ///
  /// ダウンロードの中断や重複投入で参照の無いファイルが残り、端末の容量を
  /// 食い続けるため、起動時に一度掃除する。削除した件数を返す。
  ///
  /// 利用者のファイルを消す処理なので安全弁を 3 つ置いている:
  /// 1. saved_metadata が未設定なら何もしない
  ///    (参照集合が空になり、全ファイルを消してしまう)
  /// 2. メタデータの解析に 1 件でも失敗したら中止する
  ///    (参照を取りこぼして、使われているファイルを消しかねない)
  /// 3. 更新時刻が新しいファイルは残す
  ///    (ダウンロード中のファイルはメタデータ書き込み前なので必ず
  ///     「参照なし」に見える。進行中のものを消さないための猶予)
  static Future<int> sweepOrphans({
    Duration minAge = const Duration(hours: 1),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('saved_metadata');
    if (raw == null) return 0; // 安全弁 1

    final referenced = <String>{};
    for (final s in raw) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final stored = map['localVideoPath'];
        if (stored is String && stored.isNotEmpty) {
          referenced.add(p.basename(stored));
        }
      } catch (_) {
        return 0; // 安全弁 2
      }
    }

    final dirPath = OfflineVideoPaths.directory;
    if (dirPath == null) return 0;
    final dir = Directory(dirPath);
    if (!await dir.exists()) return 0;

    final threshold = DateTime.now().subtract(minAge);
    var deleted = 0;
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        if (referenced.contains(p.basename(entity.path))) continue;
        try {
          final stat = await entity.stat();
          if (stat.modified.isAfter(threshold)) continue; // 安全弁 3
          await entity.delete();
          deleted++;
        } catch (_) {}
      }
    } catch (_) {}
    return deleted;
  }
}
