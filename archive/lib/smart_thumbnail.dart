import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

bool isLocalThumbnailPath(String? src) {
  if (src == null || src.isEmpty) return false;
  if (src.startsWith('file://')) return true;
  if (src.startsWith('/')) return true;
  return false;
}

String stripFileScheme(String src) {
  if (src.startsWith('file://')) return src.substring(7);
  return src;
}

class SmartThumbnail extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  /// ローカルファイル画像を Image.file で読む時のデコード解像度上限 (px)。
  /// ImagePicker 経由で保存された 4000x3000 級の写真を等倍デコードすると
  /// main isolate が数秒スタックするので、表示先に応じた上限を強制する
  final int cacheWidth;

  const SmartThumbnail({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.cacheWidth = 800,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocalThumbnailPath(imageUrl)) {
      final file = File(stripFileScheme(imageUrl));
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (c, e, s) =>
            errorWidget?.call(c, imageUrl, e) ??
            const Icon(Icons.image_not_supported),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
