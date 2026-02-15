import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        width: 300,
        decoration: BoxDecoration(
          color:
              colorScheme.brightness == Brightness.dark
                  ? Color(0xFF2C2C2C)
                  : colorScheme.primary,
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            SizedBox(
              width: 300,
              child:
                  imageUrl != null
                      ? (showThumbnail
                          ? Image.network(
                            imageUrl,
                            key: ValueKey(imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
              ),
            ),

            widget.listName != L10n.of(context)!.all_item_list_name
                ? Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
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
              ),
              child: Text(L10n.of(context)!.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(colorScheme.primary),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              child: Text(
                L10n.of(context)!.random_image_change_list_name_confirm,
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // ダイアログを閉じる

                // 変更処理開始
                final prefs = await SharedPreferences.getInstance();

                //変更後の名前
                final newListName = _controller.text.trim();
                if (newListName.isEmpty) {
                  return;
                }

                //all_listsを変更
                final allLists = prefs.getStringList('all_lists') ?? [];
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
