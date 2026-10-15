import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// オフライン動画ファイルのパス解決を一箇所に集約するヘルパ。
///
/// saved_metadata には **ファイル名のみ** を保存し、実際のパスは起動時に
/// 解決したディレクトリと結合して組み立てる。
///
/// 絶対パスをそのまま保存すると、iOS ではアプリ更新のたびにコンテナ UUID が
/// 変わるため参照が切れる (ファイルは残っているのに「未ダウンロード」扱いになる)。
/// 既に保存されている絶対パスも [migrateLegacyPaths] でファイル名へ書き換える。
class OfflineVideoPaths {
  OfflineVideoPaths._();

  static const dirName = 'offline_videos';

  /// 保存先ディレクトリの絶対パス。
  /// build() 内から同期的に参照するため、起動時に一度だけ解決してキャッシュする。
  static String? _dir;

  /// 解決済みディレクトリ (未初期化なら null)
  static String? get directory => _dir;

  /// アプリ起動時に一度だけ呼ぶ。runApp より前に await すること。
  static Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    _dir = p.join(docs.path, dirName);
  }

  /// 保存先ディレクトリを作成して返す (ダウンロード時に使用)
  static Future<Directory> ensureDirectory() async {
    if (_dir == null) await init();
    final dir = Directory(_dir!);
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// saved_metadata に保存する値へ変換する (ファイル名のみ)
  static String toStored(String absolutePath) => p.basename(absolutePath);

  /// saved_metadata の値から現在有効な絶対パスを組み立てる。
  ///
  /// 旧形式の絶対パスが渡された場合もファイル名だけを取り出して解決するため、
  /// 移行前のデータでもそのまま動作する。
  static String? resolve(Object? stored) {
    if (stored is! String || stored.isEmpty) return null;
    final name = p.basename(stored);
    if (name.isEmpty) return null;
    final dir = _dir;
    // 未初期化時は保存値をそのまま返す (旧挙動へのフォールバック)
    if (dir == null) return stored;
    return p.join(dir, name);
  }

  /// 保存値に対応するファイルが実在するか (同期。build() 内から呼べる)
  static bool exists(Object? stored) {
    final path = resolve(stored);
    if (path == null || path.isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// 保存値に対応する File (存在確認はしない)
  static File? fileFor(Object? stored) {
    final path = resolve(stored);
    if (path == null || path.isEmpty) return null;
    return File(path);
  }

  /// 既存データの localVideoPath を絶対パスからファイル名へ書き換える。
  /// 冪等なので複数回実行しても安全だが、毎起動の書き込みを避けるため
  /// 完了フラグを立てる。
  static const _migrationKey = 'offline_video_path_migrated_v1';

  static Future<void> migrateLegacyPaths() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) ?? false) return;

    final list = prefs.getStringList('saved_metadata') ?? [];
    if (list.isEmpty) {
      await prefs.setBool(_migrationKey, true);
      return;
    }

    var changed = false;
    final updated = list.map((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final stored = map['localVideoPath'];
        if (stored is String && stored.isNotEmpty) {
          final name = p.basename(stored);
          if (name != stored) {
            map['localVideoPath'] = name;
            changed = true;
            return jsonEncode(map);
          }
        }
        return s;
      } catch (_) {
        return s;
      }
    }).toList();

    if (changed) {
      await prefs.setStringList('saved_metadata', updated);
    }
    await prefs.setBool(_migrationKey, true);
  }
}
