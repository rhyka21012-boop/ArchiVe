import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

import 'offline_cleanup.dart';
import 'dart:ui';
import 'dart:async';
import 'thumbnail_setting_provider.dart';
import 'l10n/app_localizations.dart';

class RandomImageContainer extends ConsumerStatefulWidget {
  final String listName;
  final VoidCallback? onDeleted;
  final VoidCallback? onChanged;

  const RandomImageContainer({
    super.key,
    required this.listName,
    this.onDeleted,
    this.onChanged,
  });

  @override
  ConsumerState<RandomImageContainer> createState() =>
      _RandomImageContainerState();
}

class _RandomImageContainerState extends ConsumerState<RandomImageContainer> {
  Map<String, dynamic>? _randomItem;

  @override
  void initState() {
    super.initState();
    _loadRandomItem();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadRandomItem() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('saved_metadata') ?? [];

    final filteredItems =
        data.map((e) => jsonDecode(e) as Map<String, dynamic>).where((item) {
          // 「全てのアイテム」ならlistNameで絞り込まない
          final hasImage = item['image'] != null;
          if (widget.listName == L10n.of(context)!.all_item_list_name) {
            return hasImage;
          } else {
            return item['listName'] == widget.listName && hasImage;
          }
        }).toList();

    if (filteredItems.isNotEmpty) {
      filteredItems.shuffle();
      setState(() {
        _randomItem = filteredItems.first;
      });
    } else {
      setState(() {
        _randomItem = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showThumbnail = ref.watch(showThumbnailProvider);
    final imageUrl = _randomItem?['image'];
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final bool showImageAsBg = imageUrl != null && showThumbnail;
    // 各リスト固有の淡いプライマリ寄せ色をリスト名から決定的に生成
    final bgColor = _paleListColor(colorScheme.primary, widget.listName, isDark);
    // 画像がある時は暗いオーバーレイの上に載るので白文字、なければ背景に合わせる
    final textColor = showImageAsBg
        ? Colors.white
        : _readableTextColor(bgColor);
    final iconColor = textColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        width: 300,
        decoration: BoxDecoration(color: bgColor),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            SizedBox(
              width: 300,
              child:
                  imageUrl != null
                      ? (showThumbnail
                          ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            key: ValueKey(imageUrl),
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) {
                              return Container(
                                height: 100,
                                color: Colors.grey[300],
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      L10n.of(context)!.random_image_no_image,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                          : const SizedBox.shrink())
                      : const SizedBox.shrink(),
            ),

            if (_randomItem != null)
              if (showThumbnail)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),

            Center(
              child: Text(
                widget.listName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  shadows: showImageAsBg
                      ? const [Shadow(blurRadius: 6, color: Colors.black54)]
                      : null,
                ),
              ),
            ),

            widget.listName != L10n.of(context)!.all_item_list_name
                ? Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.more_vert, color: iconColor),
                    onPressed: () {
                      showModalBottomSheet(
                        backgroundColor: colorScheme.secondary,
                        context: context,
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    Icons.edit,
                                    color: colorScheme.onPrimary,
                                  ),
                                  title: Text(
                                    L10n.of(
                                      context,
                                    )!.random_image_change_list_name,
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                  onTap: (() async {
                                    Navigator.of(context).pop();
                                    _showChangeNameModal();
                                  }),
                                ),
                                ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: colorScheme.onPrimary,
                                  ),
                                  title: Text(
                                    L10n.of(context)!.random_image_delete_list,
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                  onTap: () async {
                                    Navigator.of(
                                      context,
                                    ).pop(); // BottomSheetを閉じてからダイアログを表示

                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          backgroundColor:
                                              colorScheme.secondary,
                                          title: Center(
                                            child: Text(
                                              L10n.of(
                                                context,
                                              )!.random_image_delete_list_dialog,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          content: Text(
                                            L10n.of(
                                              context,
                                            )!.random_image_delete_list_dialog_description,
                                            textAlign: TextAlign.center,
                                          ),
                                          actionsAlignment:
                                              MainAxisAlignment.center,
                                          actions: <Widget>[
                                            TextButton(
                                              style: ButtonStyle(
                                                elevation:
                                                    MaterialStateProperty.all(
                                                      0,
                                                    ),
                                                backgroundColor:
                                                    MaterialStateProperty.all(
                                                      Colors.grey[300],
                                                    ),
                                                foregroundColor:
                                                    MaterialStateProperty.all(
                                                      Colors.black,
                                                    ),
                                                shape: MaterialStateProperty.all(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                L10n.of(context)!.cancel,
                                              ),
                                              onPressed: () {
                                                Navigator.of(
                                                  context,
                                                ).pop(); // ダイアログを閉じる
                                              },
                                            ),
                                            TextButton(
                                              style: ButtonStyle(
                                                elevation:
                                                    MaterialStateProperty.all(
                                                      0,
                                                    ),
                                                backgroundColor:
                                                    MaterialStateProperty.all(
                                                      colorScheme.primary,
                                                    ),
                                                foregroundColor:
                                                    MaterialStateProperty.all(
                                                      Colors.white,
                                                    ),
                                                shape: MaterialStateProperty.all(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                L10n.of(
                                                  context,
                                                )!.random_image_delete_list_confirm,
                                              ),
                                              onPressed: () async {
                                                Navigator.of(
                                                  context,
                                                ).pop(); // ダイアログを閉じる
                                                // 削除処理開始
                                                final prefs =
                                                    await SharedPreferences.getInstance();

                                                //all_listsから削除
                                                final allLists =
                                                    prefs.getStringList(
                                                      'all_lists',
                                                    ) ??
                                                    [];
                                                final updatedLists =
                                                    allLists
                                                        .where(
                                                          (item) =>
                                                              item !=
                                                              widget.listName,
                                                        )
                                                        .toList();
                                                await prefs.setStringList(
                                                  'all_lists',
                                                  updatedLists,
                                                );

                                                //savedMeta_dataから削除
                                                final savedMetadata =
                                                    prefs.getStringList(
                                                      'saved_metadata',
                                                    ) ??
                                                    [];
                                                // このリストに属するアイテムの URL を抽出
                                                final urlsInList = <String>[];
                                                for (final item
                                                    in savedMetadata) {
                                                  try {
                                                    final m = jsonDecode(item)
                                                        as Map<String, dynamic>;
                                                    if (m['listName'] ==
                                                        widget.listName) {
                                                      final u = m['url']
                                                          ?.toString();
                                                      if (u != null &&
                                                          u.isNotEmpty) {
                                                        urlsInList.add(u);
                                                      }
                                                    }
                                                  } catch (_) {}
                                                }
                                                // 先にオフライン動画ファイル + prefs を削除
                                                await OfflineCleanup.forUrls(
                                                    urlsInList);
                                                final updatedMetadata =
                                                    savedMetadata.where((item) {
                                                      final map =
                                                          jsonDecode(item)
                                                              as Map<
                                                                String,
                                                                dynamic
                                                              >;
                                                      return map['listName'] !=
                                                          widget.listName;
                                                    }).toList();
                                                final success = await prefs
                                                    .setStringList(
                                                      'saved_metadata',
                                                      updatedMetadata,
                                                    );

                                                await _loadRandomItem();

                                                if (success) {
                                                  widget.onDeleted
                                                      ?.call(); //削除処理の最後に親に通知
                                                } else {}
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  //====================
  //リスト名変更のモーダル
  //====================
  void _showChangeNameModal() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _controller = TextEditingController(
          text: widget.listName,
        );
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.secondary,
          title: Text(L10n.of(context)!.random_image_change_list_name_dialog),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: L10n.of(context)!.random_image_change_list_name_hint,
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(Colors.grey[300]),
                foregroundColor: MaterialStateProperty.all(Colors.black),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: Text(L10n.of(context)!.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(colorScheme.primary),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: Text(
                L10n.of(context)!.random_image_change_list_name_confirm,
              ),
              onPressed: () async {
                // 変更後の名前
                final newListName = _controller.text.trim();
                if (newListName.isEmpty) {
                  Navigator.of(context).pop();
                  return;
                }

                final prefs = await SharedPreferences.getInstance();
                final allLists = prefs.getStringList('all_lists') ?? [];

                // 同名チェック（自分自身は除く）
                if (newListName != widget.listName &&
                    allLists.contains(newListName)) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        L10n.of(context)!
                            .search_result_page_list_already_exists,
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop(); // ダイアログを閉じる

                //all_listsを変更
                final updatedLists =
                    allLists.map((item) {
                      return item == widget.listName ? newListName : item;
                    }).toList();
                await prefs.setStringList('all_lists', updatedLists);

                //saved_metadataを変更
                final savedMetadata =
                    prefs.getStringList('saved_metadata') ?? [];
                final updatedMetadata =
                    savedMetadata.map((item) {
                      final map = jsonDecode(item) as Map<String, dynamic>;
                      if (map['listName'] == widget.listName) {
                        map['listName'] = newListName;
                      }
                      return jsonEncode(map);
                    }).toList();

                print('保存開始');
                final success = await prefs.setStringList(
                  'saved_metadata',
                  updatedMetadata,
                );
                print('保存成功？: $success');

                if (success) {
                  widget.onChanged?.call(); //変更完了を通知
                } else {
                  print('保存失敗');
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// リスト名から決定的に、プライマリカラー近傍の淡い色を生成する
Color _paleListColor(Color primary, String seed, bool isDark) {
  final baseHsl = HSLColor.fromColor(primary);
  final rng = seed.isEmpty ? 1 : seed.hashCode.abs();
  final hueShift = (rng % 41) - 20; // ±20°
  final newHue = ((baseHsl.hue + hueShift) % 360 + 360) % 360;
  if (isDark) {
    // 暗色モード: 彩度低め・明度低めのくすんだ色
    final sat = 0.25 + ((rng >> 8) % 20) / 100.0; // 0.25-0.44
    final light = 0.18 + ((rng >> 12) % 8) / 100.0; // 0.18-0.25
    return HSLColor.fromAHSL(1.0, newHue, sat, light).toColor();
  } else {
    // 明色モード: パステル調で背景と馴染ませる
    final sat = 0.35 + ((rng >> 8) % 25) / 100.0; // 0.35-0.59
    final light = 0.82 + ((rng >> 12) % 10) / 100.0; // 0.82-0.91
    return HSLColor.fromAHSL(1.0, newHue, sat, light).toColor();
  }
}

// 背景色に対して十分にコントラストのある文字色を選ぶ
Color _readableTextColor(Color bg) {
  // 相対輝度 (WCAG 準拠の簡易版) を基準に閾値で切り替え
  final luminance = bg.computeLuminance();
  return luminance > 0.5 ? Colors.black87 : Colors.white;
}
