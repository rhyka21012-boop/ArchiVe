import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import 'dart:async';

class RandomImageContainer extends StatefulWidget {
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
  State<RandomImageContainer> createState() => _RandomImageContainerState();
}

class _RandomImageContainerState extends State<RandomImageContainer> {
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
        data
            .map((e) => jsonDecode(e) as Map<String, dynamic>)
            .where(
              (item) =>
                  item['listName'] == widget.listName && item['image'] != null,
            )
            .toList();

    if (filteredItems.isNotEmpty) {
      filteredItems.shuffle();
      setState(() {
        _randomItem = filteredItems.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                              children: const [
                                Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '画像を読み込めません',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                      : const SizedBox.shrink(),
            ),

            if (_randomItem != null)
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

            Positioned(
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
                                'リスト名を変更',
                                style: TextStyle(color: colorScheme.onPrimary),
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
                                'リストを削除',
                                style: TextStyle(color: colorScheme.onPrimary),
                              ),
                              onTap: () async {
                                Navigator.of(
                                  context,
                                ).pop(); // BottomSheetを閉じてからダイアログを表示

                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: colorScheme.secondary,
                                      title: const Center(
                                        child: Text(
                                          'このリストを削除しますか？',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      content: const Text(
                                        'リスト内のアイテムも削除されます。',
                                        textAlign: TextAlign.center,
                                      ),
                                      actionsAlignment:
                                          MainAxisAlignment.center,
                                      actions: <Widget>[
                                        TextButton(
                                          style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                  Colors.grey[300],
                                                ),
                                            foregroundColor:
                                                MaterialStateProperty.all(
                                                  Colors.black,
                                                ),
                                          ),
                                          child: const Text('キャンセル'),
                                          onPressed: () {
                                            Navigator.of(
                                              context,
                                            ).pop(); // ダイアログを閉じる
                                          },
                                        ),
                                        TextButton(
                                          style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                  colorScheme.primary,
                                                ),
                                            foregroundColor:
                                                MaterialStateProperty.all(
                                                  Colors.white,
                                                ),
                                          ),
                                          child: const Text('削除'),
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
            ),
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
          title: Text('リスト名を変更'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'リスト名を入力',
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.grey[300]),
                foregroundColor: MaterialStateProperty.all(Colors.black),
              ),
              child: Text('キャンセル'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(colorScheme.primary),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              child: Text('変更'),
              onPressed: () async {
                Navigator.of(context).pop(); // ダイアログを閉じる

                // 変更処理開始
                final prefs = await SharedPreferences.getInstance();

                //変更後の名前
                final newListName = _controller.text.trim();
                if (newListName.isEmpty) {
                  print('新しいリスト名が空です');
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
