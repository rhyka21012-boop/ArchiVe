import 'package:flutter/services.dart';

class DebugLogService {
  static const MethodChannel _channel = MethodChannel('debug_log_channel');

  /// Swift側のログ取得
  static Future<List<String>> getLogs() async {
    final List<dynamic> logs = await _channel.invokeMethod('getLogs');
    return logs.cast<String>();
  }

  /// ログ削除
  static Future<void> clearLogs() async {
    await _channel.invokeMethod('clearLogs');
  }

  /// Flutter側ログ追加
  static Future<void> add(String message) async {
    await _channel.invokeMethod('addLog', {"message": message});
  }
}
