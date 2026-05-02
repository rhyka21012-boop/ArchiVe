import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// iOS App Groups 経由で Share Extension とデータをやり取りするサービス。
/// Android では全メソッドが即返却するため、呼び出し元で分岐不要。
class AppGroupService {
  static const _channel = MethodChannel('com.walkinggoblins.archive/app_groups');

  /// Share Extension が書き込んだ pending データを取得する。
  /// データがなければ null を返す。
  static Future<Map<String, dynamic>?> getPendingShare() async {
    if (!Platform.isIOS) return null;
    try {
      final json = await _channel.invokeMethod<String>('getPendingShare');
      if (json == null || json.isEmpty) return null;
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 処理済みの pending データを削除する。
  static Future<void> clearPendingShare() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('clearPendingShare');
    } catch (_) {}
  }

  /// Share Extension がリスト一覧を読めるよう App Groups に同期する。
  /// リストの追加・削除のたびに呼び出す。
  static Future<void> syncAllLists(List<String> lists) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('syncAllLists', lists);
    } catch (_) {}
  }
}
