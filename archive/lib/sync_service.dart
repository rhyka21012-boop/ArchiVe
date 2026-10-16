import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'offline_video_path.dart';
import 'rating_label_provider.dart';

/// Pro 機能のクラウド同期サービス
/// Firestore に users/{uid}/items, lists, rankings, preferences を保持
///
/// 端末固有のもの (オフライン動画の実体、テーマ等) は持ち出さない。
/// オフライン動画は実体ではなく「欲しい」という印だけを持ち、
/// 復元時に再ダウンロードする。
class SyncService {
  static final _firestore = FirebaseFirestore.instance;

  static String? get _uid => AuthService.currentUser?.uid;
  static bool get isAuthed => _uid != null;

  // ============================================================
  // コレクション参照
  // ============================================================
  static CollectionReference<Map<String, dynamic>>? _itemsCol() {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('items');
  }

  static CollectionReference<Map<String, dynamic>>? _listsCol() {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('lists');
  }

  static CollectionReference<Map<String, dynamic>>? _rankingsCol() {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('rankings');
  }

  // ============================================================
  // ID 生成（URL ハッシュ）
  // ============================================================
  /// 端末ローカルにのみ意味を持つフィールド。
  /// オフライン動画の実体は端末内にしか無いため、クラウドへ持ち出すと
  /// 別端末に「ダウンロード済み」の誤った状態が復元されてしまう。
  static const _localOnlyKeys = {
    'localVideoPath',
    'localVideoSize',
    'localVideoDownloadedAt',
  };

  /// オフラインで持っておきたい作品かどうかの印。
  ///
  /// 実体のパスは端末固有なのでクラウドへ出せないが、「ダウンロード済み
  /// だった」という意思だけは別端末へ引き継ぎたい。復元時にこの印を見て
  /// 再ダウンロードする。
  static const _kOfflineWanted = 'offlineWanted';

  /// クラウドへ送る前にローカル専用フィールドを取り除き、
  /// 代わりにオフライン希望の印を立てる。
  ///
  /// 印は保存値ではなく localVideoPath の有無から毎回決める。
  /// こうしないと、オフライン動画を削除したあとにバックアップしても
  /// 印が残り続け、復元時に不要な再ダウンロードが走る。
  static Map<String, dynamic> _stripLocalOnly(Map<String, dynamic> item) {
    final copy = Map<String, dynamic>.from(item);
    final hasLocal =
        (item['localVideoPath']?.toString().trim() ?? '').isNotEmpty;
    copy.removeWhere((k, _) => _localOnlyKeys.contains(k));
    if (hasLocal) {
      copy[_kOfflineWanted] = true;
    } else {
      copy.remove(_kOfflineWanted);
    }
    return copy;
  }

  /// URL から決定的なドキュメントIDを生成（重複防止）
  static String itemIdFromUrl(String url) {
    final bytes = utf8.encode(url);
    return sha256.convert(bytes).toString().substring(0, 24);
  }

  // ============================================================
  // クラウド側の掃除
  // ============================================================
  /// ローカルに無いドキュメントをクラウドから消し、内容を一致させる。
  ///
  /// set だけでは以前バックアップした分が残り続け、ローカルで削除した
  /// 作品が復元で戻ってきてしまう。バックアップのたびにここで差分を消す。
  ///
  /// [keepIds] が空のときは何もしない。
  /// 入れ直し直後などローカルが空の状態でバックアップを押しただけで
  /// クラウドの控えが丸ごと消えるのを防ぐ (消すと取り返しがつかない)。
  static Future<int> _deleteStaleDocs(
    CollectionReference<Map<String, dynamic>> col,
    Set<String> keepIds,
  ) async {
    if (keepIds.isEmpty) return 0;
    try {
      final snapshot = await col.get();
      final stale =
          snapshot.docs.where((d) => !keepIds.contains(d.id)).toList();
      if (stale.isEmpty) return 0;
      // バッチは 1 回 500 操作までなので分割する
      for (var i = 0; i < stale.length; i += 500) {
        final end = (i + 500 < stale.length) ? i + 500 : stale.length;
        final batch = _firestore.batch();
        for (final doc in stale.sublist(i, end)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      return stale.length;
    } catch (e) {
      debugPrint('_deleteStaleDocs error: $e');
      return 0;
    }
  }

  // ============================================================
  // アイテム CRUD
  // ============================================================
  /// 単一アイテムを Firestore に保存（書き込み時のフック）
  static Future<void> upsertItem(Map<String, dynamic> item) async {
    final col = _itemsCol();
    if (col == null) return;
    final url = (item['url'] as String?)?.trim() ?? '';
    if (url.isEmpty) return;
    try {
      await col.doc(itemIdFromUrl(url)).set({
        ..._stripLocalOnly(item),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('upsertItem error: $e');
    }
  }

  /// 単一アイテムを削除
  static Future<void> deleteItem(String url) async {
    final col = _itemsCol();
    if (col == null) return;
    try {
      await col.doc(itemIdFromUrl(url)).delete();
    } catch (e) {
      debugPrint('deleteItem error: $e');
    }
  }

  /// 全ローカルアイテムをアップロード（初回マイグレーション用）
  /// 戻り値: アップロード件数
  static Future<int> uploadAllLocalItems() async {
    final col = _itemsCol();
    if (col == null) return 0;

    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('saved_metadata') ?? [];
    if (items.isEmpty) return 0;

    // 500件ずつバッチ書き込み
    int total = 0;
    final keepIds = <String>{};
    for (var i = 0; i < items.length; i += 500) {
      final end = (i + 500 < items.length) ? i + 500 : items.length;
      final batch = _firestore.batch();
      for (final itemJson in items.sublist(i, end)) {
        try {
          final item = jsonDecode(itemJson) as Map<String, dynamic>;
          final url = (item['url'] as String?)?.trim() ?? '';
          if (url.isEmpty) continue;
          final docId = itemIdFromUrl(url);
          batch.set(col.doc(docId), {
            ..._stripLocalOnly(item),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          keepIds.add(docId);
          total++;
        } catch (e) {
          debugPrint('Skip invalid item: $e');
        }
      }
      await batch.commit();
    }
    // ローカルで削除済みの作品をクラウドからも消す
    await _deleteStaleDocs(col, keepIds);
    return total;
  }

  /// Firestore からダウンロードしてローカル(saved_metadata) を上書き
  /// 戻り値: ダウンロード件数
  static Future<int> downloadAllItems() async {
    final col = _itemsCol();
    if (col == null) return 0;

    final prefs = await SharedPreferences.getInstance();

    // 既存ローカルのオフライン動画情報を URL 単位で退避しておく。
    // クラウド側はこれらを保持しないため、単純に上書きすると
    // ダウンロード済みの参照が全て失われる (ファイルは端末に残ったまま)。
    final localOnlyByUrl = <String, Map<String, dynamic>>{};
    for (final s in prefs.getStringList('saved_metadata') ?? <String>[]) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final url = (map['url'] as String?)?.trim();
        if (url == null || url.isEmpty) continue;
        final kept = <String, dynamic>{};
        for (final k in _localOnlyKeys) {
          if (map.containsKey(k)) kept[k] = map[k];
        }
        if (kept.isNotEmpty) localOnlyByUrl[url] = kept;
      } catch (_) {}
    }

    final snapshot = await col.get();
    final items = <String>[];
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data.remove('updatedAt'); // ローカル形式に戻すため除外
      final url = (data['url'] as String?)?.trim();
      if (url != null && localOnlyByUrl.containsKey(url)) {
        data.addAll(localOnlyByUrl[url]!);
      }
      items.add(jsonEncode(data));
    }
    await prefs.setStringList('saved_metadata', items);
    return items.length;
  }

  // ============================================================
  // リスト同期
  // ============================================================
  /// 全リストをアップロード
  static Future<int> uploadAllLists() async {
    final col = _listsCol();
    if (col == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    final lists = prefs.getStringList('all_lists') ?? [];

    final batch = _firestore.batch();
    final keepIds = <String>{};
    for (var i = 0; i < lists.length; i++) {
      final docId = i.toString().padLeft(4, '0');
      batch.set(col.doc(docId), {
        'name': lists[i],
        'order': i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      keepIds.add(docId);
    }
    if (lists.isNotEmpty) await batch.commit();
    // リストが減ったとき、末尾の連番ドキュメントが残って復元で復活する
    await _deleteStaleDocs(col, keepIds);
    return lists.length;
  }

  /// Firestore からリストをダウンロード
  static Future<int> downloadAllLists() async {
    final col = _listsCol();
    if (col == null) return 0;
    final snapshot = await col.orderBy('order').get();
    final lists = snapshot.docs
        .map((d) => d.data()['name'] as String?)
        .whereType<String>()
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('all_lists', lists);
    return lists.length;
  }

  // ============================================================
  // ランキング同期
  // ============================================================
  /// ランキングデータをアップロード
  static Future<int> uploadAllRankings() async {
    final col = _rankingsCol();
    if (col == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    final rankings = prefs.getStringList('saved_ranking') ?? [];

    int count = 0;
    final batch = _firestore.batch();
    final keepIds = <String>{};
    for (final rankingJson in rankings) {
      try {
        final r = jsonDecode(rankingJson) as Map<String, dynamic>;
        final listName = r['listName'] as String? ?? '';
        if (listName.isEmpty) continue;
        // listNameをIDとして使用（特殊文字対応）
        final docId = sha256.convert(utf8.encode(listName)).toString().substring(0, 24);
        batch.set(col.doc(docId), {
          ...r,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        keepIds.add(docId);
        count++;
      } catch (e) {
        debugPrint('Skip invalid ranking: $e');
      }
    }
    if (count > 0) await batch.commit();
    // 削除したリストのランキングが残って復元で復活する
    await _deleteStaleDocs(col, keepIds);
    return count;
  }

  /// ランキングをダウンロード
  static Future<int> downloadAllRankings() async {
    final col = _rankingsCol();
    if (col == null) return 0;
    final snapshot = await col.get();
    final rankings = <String>[];
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data.remove('updatedAt');
      rankings.add(jsonEncode(data));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_ranking', rankings);
    return rankings.length;
  }

  // ============================================================
  // 設定の同期
  // ============================================================
  /// 端末をまたいで引き継ぐ設定。
  ///
  /// テーマや表示設定は端末ごとに変えたいことがあるので持ち出さない。
  /// ここに入れるのは「利用者が作ったもの」と「購入/視聴で得たもの」に限る。
  static const _syncedStringPrefs = [
    'rating_label_$kRatingCritical',
    'rating_label_$kRatingNormal',
    'rating_label_$kRatingManiac',
  ];

  static const _syncedIntPrefs = [
    // 広告視聴で増やした保存枠
    'extra_save_limit',
  ];

  static DocumentReference<Map<String, dynamic>>? _prefsDoc() {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('preferences').doc('app');
  }

  /// 評価名・タグ名・保存枠をアップロード
  static Future<int> uploadPreferences() async {
    final doc = _prefsDoc();
    if (doc == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    for (final key in _syncedStringPrefs) {
      final v = prefs.getString(key);
      if (v != null && v.isNotEmpty) data[key] = v;
    }
    for (final category in kTagCategories) {
      final key = 'tag_label_$category';
      final v = prefs.getString(key);
      if (v != null && v.isNotEmpty) data[key] = v;
    }
    for (final key in _syncedIntPrefs) {
      final v = prefs.getInt(key);
      if (v != null) data[key] = v;
    }
    try {
      await doc.set({...data, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('uploadPreferences error: $e');
      return 0;
    }
    return data.length;
  }

  /// 評価名・タグ名・保存枠をダウンロード。
  ///
  /// クラウドに無い項目はローカルの値を消す (未設定へ戻す)。
  /// 残してしまうと、改名をやめた状態を別端末へ引き継げない。
  static Future<int> downloadPreferences() async {
    final doc = _prefsDoc();
    if (doc == null) return 0;
    final Map<String, dynamic> data;
    try {
      final snapshot = await doc.get();
      if (!snapshot.exists) return 0;
      data = snapshot.data() ?? const {};
    } catch (e) {
      debugPrint('downloadPreferences error: $e');
      return 0;
    }

    final prefs = await SharedPreferences.getInstance();
    var applied = 0;
    final stringKeys = [
      ..._syncedStringPrefs,
      for (final category in kTagCategories) 'tag_label_$category',
    ];
    for (final key in stringKeys) {
      final v = data[key]?.toString();
      if (v == null || v.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, v);
        applied++;
      }
    }
    for (final key in _syncedIntPrefs) {
      final v = (data[key] as num?)?.toInt();
      if (v == null) {
        await prefs.remove(key);
      } else {
        await prefs.setInt(key, v);
        applied++;
      }
    }
    return applied;
  }

  // ============================================================
  // オフライン動画の再ダウンロード
  // ============================================================
  /// 復元後、再ダウンロードが必要な作品を返す。
  ///
  /// 「クラウドでオフライン希望が立っている」かつ「端末に実体が無い」もの。
  /// 同じ端末での復元ではローカル専用フィールドを退避しているため、
  /// 既にある分はここに出てこない。
  static Future<List<Map<String, dynamic>>> pendingOfflineRestores() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = <Map<String, dynamic>>[];
    for (final s in prefs.getStringList('saved_metadata') ?? <String>[]) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        if (map[_kOfflineWanted] != true) continue;
        final url = (map['url'] as String?)?.trim() ?? '';
        if (url.isEmpty) continue;
        if (OfflineVideoPaths.exists(map['localVideoPath'])) continue;
        pending.add(map);
      } catch (_) {}
    }
    return pending;
  }

  // ============================================================
  // 一括同期
  // ============================================================
  /// 全データをアップロード
  static Future<Map<String, int>> uploadAll() async {
    return {
      'items': await uploadAllLocalItems(),
      'lists': await uploadAllLists(),
      'rankings': await uploadAllRankings(),
      'preferences': await uploadPreferences(),
    };
  }

  /// 全データをダウンロード
  static Future<Map<String, int>> downloadAll() async {
    return {
      'items': await downloadAllItems(),
      'lists': await downloadAllLists(),
      'rankings': await downloadAllRankings(),
      'preferences': await downloadPreferences(),
    };
  }
}
