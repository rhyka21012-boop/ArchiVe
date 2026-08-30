import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ユーザーの行動データ (作品保存数 / ログイン数 / AI 利用数など) を
/// Firestore `user_activity/{uid}` に蓄積するサービス。
///
/// - Firebase Auth に未サインインでも匿名でサインインして uid を確保
/// - 全てのメソッドは失敗を握りつぶす (ネットワーク不良や権限問題で本体機能を止めない)
/// - 集計は Cloud Function 側で行う (dev_stats_page から呼び出す)
class ActivityService {
  static final _firestore = FirebaseFirestore.instance;

  /// 未サインインなら匿名サインインして uid を返す。失敗時は null。
  static Future<String?> _ensureUid() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
        user = FirebaseAuth.instance.currentUser;
      }
      return user?.uid;
    } catch (e) {
      debugPrint('ActivityService _ensureUid error: $e');
      return null;
    }
  }

  static DocumentReference<Map<String, dynamic>> _docFor(String uid) =>
      _firestore.collection('user_activity').doc(uid);

  /// アプリ起動時に呼ぶ。launchCount 加算 + 最新のプロファイル情報を同期
  static Future<void> recordLaunch({
    required String plan,
    required String appVersion,
    required String locale,
  }) async {
    final uid = await _ensureUid();
    if (uid == null) return;
    final platform = Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other');
    try {
      await _docFor(uid).set({
        'launchCount': FieldValue.increment(1),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'firstSeenAt': FieldValue.serverTimestamp(),
        'platform': platform,
        'appVersion': appVersion,
        'plan': plan,
        'locale': locale,
      }, SetOptions(merge: true));
      // firstSeenAt はすでに存在するなら上書きしないため、
      // merge 後に「未セット時のみセット」を別途行う
      final snap = await _docFor(uid).get();
      final data = snap.data();
      if (data != null && data['firstSeenAt'] == null) {
        await _docFor(uid).set(
          {'firstSeenAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('ActivityService recordLaunch error: $e');
    }
  }

  /// 作品を新規保存した時に呼ぶ (更新は含めない)
  static Future<void> incrementSaveCount() async {
    final uid = await _ensureUid();
    if (uid == null) return;
    try {
      await _docFor(uid).set({
        'saveCount': FieldValue.increment(1),
        'lastSaveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ActivityService incrementSaveCount error: $e');
    }
  }

  /// AI タグ提案を実行した時に呼ぶ
  static Future<void> incrementAiSuggestCount() async {
    final uid = await _ensureUid();
    if (uid == null) return;
    try {
      await _docFor(uid).set({
        'aiSuggestCount': FieldValue.increment(1),
        'lastAiAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ActivityService incrementAiSuggestCount error: $e');
    }
  }

  /// プラン変更時に単発で呼ぶ (Pro 加入等)
  static Future<void> updatePlan(String plan) async {
    final uid = await _ensureUid();
    if (uid == null) return;
    try {
      await _docFor(uid).set({
        'plan': plan,
        'planUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ActivityService updatePlan error: $e');
    }
  }
}
