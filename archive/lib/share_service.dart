import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// 公開リスト共有用サービス（Pro機能）
class ShareService {
  static final _firestore = FirebaseFirestore.instance;
  static const _collection = 'shared_lists';

  /// 公開URLのベースドメイン（Firebase Hosting）
  static const _hostingBase = 'https://archive-e4efc.web.app';
  static const int maxItems = 200;

  static CollectionReference<Map<String, dynamic>> _col() =>
      _firestore.collection(_collection);

  /// リストを公開して共有IDを返す
  /// items はそのまま items 配列フィールドに格納（最大 maxItems 件）
  static Future<String> shareList({
    required String listName,
    required List<Map<String, dynamic>> items,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw StateError('Sign-in required');
    }

    final limited = items.take(maxItems).toList();
    final doc = _col().doc();
    await doc.set({
      'ownerUid': user.uid,
      'listName': listName,
      'itemCount': limited.length,
      'createdAt': FieldValue.serverTimestamp(),
      'items': limited,
    });
    debugPrint('Shared list: ${doc.id}');
    return doc.id;
  }

  /// 既存共有を新しい内容で更新（差分なくシンプルに丸ごと置き換え）
  static Future<void> updateShare({
    required String shareId,
    required String listName,
    required List<Map<String, dynamic>> items,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw StateError('Sign-in required');
    final limited = items.take(maxItems).toList();
    await _col().doc(shareId).update({
      'listName': listName,
      'itemCount': limited.length,
      'items': limited,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 共有を解除（ドキュメント削除）
  static Future<void> unshare(String shareId) async {
    await _col().doc(shareId).delete();
  }

  /// 自分の共有一覧を取得
  static Future<List<SharedListInfo>> myShares() async {
    final user = AuthService.currentUser;
    if (user == null) return [];
    final snapshot = await _col()
        .where('ownerUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(SharedListInfo.fromDoc).toList();
  }

  /// リスト名から既存の共有を探す（同名リストの重複作成防止用）
  static Future<SharedListInfo?> findShareByListName(String listName) async {
    final user = AuthService.currentUser;
    if (user == null) return null;
    final snapshot = await _col()
        .where('ownerUid', isEqualTo: user.uid)
        .where('listName', isEqualTo: listName)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return SharedListInfo.fromDoc(snapshot.docs.first);
  }

  /// 共有URLを生成
  static String shareUrl(String shareId) => '$_hostingBase/s/$shareId';
}

class SharedListInfo {
  final String shareId;
  final String listName;
  final int itemCount;
  final DateTime? createdAt;

  SharedListInfo({
    required this.shareId,
    required this.listName,
    required this.itemCount,
    this.createdAt,
  });

  factory SharedListInfo.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final created = data['createdAt'];
    return SharedListInfo(
      shareId: doc.id,
      listName: data['listName'] as String? ?? '',
      itemCount: (data['itemCount'] as num?)?.toInt() ?? 0,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  String get shareUrl => ShareService.shareUrl(shareId);
}
