import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// iOS App Groups / Android MethodChannel 経由で Share とデータをやり取りするサービス。
class AppGroupService {
  static const _channel = MethodChannel('com.walkinggoblins.archive/app_groups');
  static const _shareChannel = MethodChannel('com.walkinggoblins.archive/share');

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

  /// Android: MainActivity が受け取った共有 URL を取得する。
  static Future<String?> getSharedUrl() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _shareChannel.invokeMethod<String>('getSharedUrl');
    } catch (_) {
      return null;
    }
  }

  /// Android: 処理済みの共有 URL をクリアする。
  static Future<void> clearSharedUrl() async {
    if (!Platform.isAndroid) return;
    try {
      await _shareChannel.invokeMethod<void>('clearSharedUrl');
    } catch (_) {}
  }
}
