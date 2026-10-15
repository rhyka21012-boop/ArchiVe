import 'dart:io';

import 'package:background_downloader/background_downloader.dart' as bg;
import 'package:flutter/services.dart';

/// 通知権限の状態確認と、設定画面への誘導をまとめたサービス。
///
/// なぜ必要か:
/// Android では通知が拒否されていると前景サービスの通知を掲示できず、
/// 前景サービスそのものが成立しない。すると OS からは背景アプリ扱いのままで、
/// 従量制 (モバイル) 回線ではダウンロード中のソケットが遮断される。
/// 実測では一時的な通信猶予の失効から約 20 秒後に
/// `SocketException: Software caused connection abort` で落ちていた。
///
/// iOS は通知が拒否されていても URLSession のバックグラウンド転送が継続するため、
/// 同じ警告を出す必要はない。[backgroundDownloadsNeedNotifications] で切り分ける。
class NotificationSettingsService {
  NotificationSettingsService._();

  static const _channel =
      MethodChannel('com.walkinggoblins.archive/app_settings');

  /// 通知が無いとバックグラウンドのダウンロードが止まるプラットフォームか。
  static bool get backgroundDownloadsNeedNotifications => Platform.isAndroid;

  /// 通知権限が拒否されているか。
  ///
  /// 未決定 (まだ一度も尋ねていない) は false を返す。その場合は
  /// 通常の権限要求ダイアログが出せるので、設定画面へ送る必要がない。
  static Future<bool> isNotificationDenied() async {
    if (!backgroundDownloadsNeedNotifications) return false;
    try {
      final status = await bg.FileDownloader()
          .permissions
          .status(bg.PermissionType.notifications);
      return status == bg.PermissionStatus.denied;
    } catch (_) {
      // 判定できないときは警告を出さない (誤って急かさないため)
      return false;
    }
  }

  /// 通知設定画面を開く。開けたら true。
  static Future<bool> openNotificationSettings() async {
    try {
      final ok =
          await _channel.invokeMethod<bool>('openNotificationSettings');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}
