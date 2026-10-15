import 'dart:convert';

import 'package:http/http.dart' as http;

/// `http.Response.body` は Content-Type に charset が無いとき RFC に従い
/// latin1 でデコードするため、charset を宣言しない UTF-8 サイトで文字化けする。
/// このヘルパは charset を明示的に判定してデコードする。
///
/// 判定順:
/// 1. Content-Type の charset が latin1 系 → latin1
/// 2. それ以外 (utf-8 明示 / 未宣言 / 未対応の legacy 系) → UTF-8
///    (未宣言のサイトは実運用上ほぼ UTF-8 のため)
String decodeHttpBody(http.Response response) {
  final contentType = response.headers['content-type']?.toLowerCase() ?? '';
  final charset = RegExp(r'''charset=["']?([\w\-]+)''')
      .firstMatch(contentType)
      ?.group(1);

  const latin1Names = {'iso-8859-1', 'latin1', 'latin-1', 'ascii', 'us-ascii'};
  if (charset != null && latin1Names.contains(charset)) {
    return latin1.decode(response.bodyBytes, allowInvalid: true);
  }

  return utf8.decode(response.bodyBytes, allowMalformed: true);
}
