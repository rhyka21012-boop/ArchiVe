import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

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
        final path = map['localVideoPath'] as String?;
        if (path != null && path.isNotEmpty) {
          try {
            final f = File(path);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }

        // 前回再生位置 / 動画長さの prefs も削除
        await prefs.remove('offline_pos_$url');
        await prefs.remove('offline_dur_$url');
      } catch (_) {}
    }
  }
}
