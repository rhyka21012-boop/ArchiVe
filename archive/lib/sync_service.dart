import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Pro 機能のクラウド同期サービス
/// Firestore に users/{uid}/items, lists, rankings, preferences を保持
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
  /// URL から決定的なドキュメントIDを生成（重複防止）
  static String itemIdFromUrl(String url) {
    final bytes = utf8.encode(url);
    return sha256.convert(bytes).toString().substring(0, 24);
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
        ...item,
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
    for (var i = 0; i < items.length; i += 500) {
      final end = (i + 500 < items.length) ? i + 500 : items.length;
      final batch = _firestore.batch();
      for (final itemJson in items.sublist(i, end)) {
        try {
          final item = jsonDecode(itemJson) as Map<String, dynamic>;
          final url = (item['url'] as String?)?.trim() ?? '';
          if (url.isEmpty) continue;
          batch.set(col.doc(itemIdFromUrl(url)), {
            ...item,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          total++;
        } catch (e) {
          debugPrint('Skip invalid item: $e');
        }
      }
      await batch.commit();
    }
    return total;
  }

  /// Firestore からダウンロードしてローカル(saved_metadata) を上書き
  /// 戻り値: ダウンロード件数
  static Future<int> downloadAllItems() async {
    final col = _itemsCol();
    if (col == null) return 0;

    final snapshot = await col.get();
    final items = <String>[];
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data.remove('updatedAt'); // ローカル形式に戻すため除外
      items.add(jsonEncode(data));
    }
    final prefs = await SharedPreferences.getInstance();
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
    for (var i = 0; i < lists.length; i++) {
      batch.set(col.doc(i.toString().padLeft(4, '0')), {
        'name': lists[i],
        'order': i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    if (lists.isNotEmpty) await batch.commit();
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
        count++;
      } catch (e) {
        debugPrint('Skip invalid ranking: $e');
      }
    }
    if (count > 0) await batch.commit();
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
  // 一括同期
  // ============================================================
  /// 全データをアップロード
  static Future<Map<String, int>> uploadAll() async {
    return {
      'items': await uploadAllLocalItems(),
      'lists': await uploadAllLists(),
      'rankings': await uploadAllRankings(),
    };
  }

  /// 全データをダウンロード
  static Future<Map<String, int>> downloadAll() async {
    return {
      'items': await downloadAllItems(),
      'lists': await downloadAllLists(),
      'rankings': await downloadAllRankings(),
    };
  }
}
