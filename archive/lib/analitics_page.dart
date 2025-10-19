import 'dart:convert';
import 'dart:ui';
//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => AnalyticsPageState();
}

class AnalyticsPageState extends State<AnalyticsPage> {
  List<int> hourBuckets = List.filled(8, 0);

  Map<String, int> ratingCounts = {'critical': 0, 'normal': 0, 'maniac': 0};
  Map<String, int> castCounts = {};
  Map<String, int> genreCounts = {};
  Map<String, int> seriesCounts = {};
  Map<String, int> labelCounts = {};
  Map<String, int> makerCounts = {};

  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
    _loadViewingCountByRating();
    _loadTop5ViewingStats();
    _checkSubscriptionStatus();
  }

  Future<void> _loadAllStats() async {
    setState(() {
      // 状態を初期化（上書き）
      hourBuckets = List.filled(8, 0);
      ratingCounts = {'critical': 0, 'normal': 0, 'maniac': 0};
      castCounts.clear();
      genreCounts.clear();
      seriesCounts.clear();
      labelCounts.clear();
      makerCounts.clear();
    });

    //await _loadWatchHistory(); // Firebaseから読み込み
    await _loadSharedPrefStats(); // SharedPreferencesから読み込み
  }

  /// サブスクリプション状態を確認
  Future<void> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isActive =
          customerInfo.entitlements.all["Premium Plan"]?.isActive ?? false;
      setState(() {
        _isPremium = isActive;
      });
    } catch (e) {
      debugPrint("Error fetching subscription status: $e");
    }
  }

  /*
  Future<void> _loadWatchHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('watch_history')
            .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = data['timestamp'];
      if (timestamp is Timestamp) {
        final hour = timestamp.toDate().hour;
        final bucketIndex = hour ~/ 3;
        if (bucketIndex >= 0 && bucketIndex < 8) {
          hourBuckets[bucketIndex]++;
        }
      }
    }
  }
  */

  Future<void> _loadSharedPrefStats() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('saved_metadata') ?? [];

    for (final item in savedList) {
      final map = jsonDecode(item) as Map<String, dynamic>;

      // 評価
      final rating = map['rating'];
      final validRating =
          ['critical', 'normal', 'maniac'].contains(rating)
              ? rating
              : 'unrated';
      ratingCounts[validRating] = (ratingCounts[validRating] ?? 0) + 1;

      // 出演
      final cast = map['cast']?.toString().trim();
      if (cast != null && cast.isNotEmpty) {
        // #で分割してからでない文字列だけを対象にする
        final castList = cast
            .split('#')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty);
        for (final name in castList) {
          castCounts[name] = (castCounts[cast] ?? 0) + 1;
        }
      }
      /*
      final cast = map['cast']?.toString().trim();
      if (cast != null && cast.isNotEmpty) {
        castCounts[cast] = (castCounts[cast] ?? 0) + 1;
      }
      */

      // ジャンル
      final genre = map['genre']?.toString().trim();
      if (genre != null && genre.isNotEmpty) {
        // #で分割してからでない文字列だけを対象にする
        final genreList = genre
            .split('#')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty);
        for (final name in genreList) {
          genreCounts[name] = (genreCounts[genre] ?? 0) + 1;
        }
      }

      // シリーズ
      final series = map['series']?.toString().trim();
      if (series != null && series.isNotEmpty) {
        // #で分割してからでない文字列だけを対象にする
        final seriesList = series
            .split('#')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty);
        for (final name in seriesList) {
          seriesCounts[name] = (seriesCounts[series] ?? 0) + 1;
        }
      }

      // レーベル
      final label = map['label']?.toString().trim();
      if (label != null && label.isNotEmpty) {
        // #で分割してからでない文字列だけを対象にする
        final labelList = label
            .split('#')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty);
        for (final name in labelList) {
          labelCounts[name] = (labelCounts[label] ?? 0) + 1;
        }
      }

      // メーカー
      final maker = map['maker']?.toString().trim();
      if (maker != null && maker.isNotEmpty) {
        // #で分割してからでない文字列だけを対象にする
        final makerList = maker
            .split('#')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty);
        for (final name in makerList) {
          makerCounts[name] = (makerCounts[maker] ?? 0) + 1;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('統計情報', style: TextStyle(color: colorScheme.onPrimary)),
        actions: [
          IconButton(
            onPressed: () {
              _loadAllStats();
              _loadViewingCountByRating();
              _loadTop5ViewingStats();
            },
            icon: Icon(Icons.refresh),
            color:
                colorScheme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTitle('視聴回数'),
                Container(
                  padding: EdgeInsets.only(
                    left: 30,
                    right: 30,
                    top: 0,
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        colorScheme.brightness == Brightness.light
                            ? Colors.grey[200]
                            : Color(0xFF2C2C2C),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: Text(
                          '視聴回数TOP5',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 270,
                        child:
                            top5Viewings.isEmpty
                                ? const Center(child: Text('データがありません'))
                                : BarChart(top5ViewingBarChartData()),
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildTitle('評価'),
                Container(
                  padding: EdgeInsets.only(
                    left: 30,
                    right: 30,
                    top: 0,
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        colorScheme.brightness == Brightness.light
                            ? Colors.grey[200]
                            : Color(0xFF2C2C2C),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: Text(
                          '評価の割合',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 270,
                        child: PieChart(ratingPieChartData()),
                      ),
                      Container(
                        height: 70,
                        alignment: Alignment.center,
                        child: Text(
                          '評価毎の視聴回数',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 220,
                        child: BarChart(viewingCountBarChartData()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildTitle('出演'),
                Container(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 10,
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        colorScheme.brightness == Brightness.light
                            ? Colors.grey[200]
                            : Color(0xFF2C2C2C),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: Text(
                          '出演の割合',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 270,
                        child: PieChart(castPieChartData()),
                      ),
                      Container(
                        height: 70,
                        alignment: Alignment.center,
                        child: Text(
                          'アイテム数TOP5',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 300, child: buildTop5CastList()),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                _buildTitle('ジャンル'),
                Container(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 10,
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        colorScheme.brightness == Brightness.light
                            ? Colors.grey[200]
                            : Color(0xFF2C2C2C),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: Text(
                          'ジャンルの割合',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 270,
                        child: PieChart(genrePieChartData()),
                      ),
                      Container(
                        height: 70,
                        alignment: Alignment.center,
                        child: Text(
                          'アイテム数TOP5',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 300, child: buildTop5GenreList()),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildTitle('シリーズ'),
                Container(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 10,
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        colorScheme.brightness == Brightness.light
                            ? Colors.grey[200]
                            : Color(0xFF2C2C2C),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: Text(
                          'シリーズの割合',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 270,
                        child: PieChart(seriesPieChartData()),
                      ),
                      Container(
                        height: 70,
                        alignment: Alignment.center,
                        child: Text(
                          'アイテム数TOP5',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 300, child: buildTop5SeriesList()),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildTitle('レーベル'),
                Container(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 10,
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        colorScheme.brightness == Brightness.light
                            ? Colors.grey[200]
                            : Color(0xFF2C2C2C),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: Text(
                          'レーベルの割合',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 270,
                        child: PieChart(labelPieChartData()),
                      ),
                      Container(
                        height: 70,
                        alignment: Alignment.center,
                        child: Text(
                          'アイテム数TOP5',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 300, child: buildTop5LabelList()),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildTitle('メーカー'),
                Container(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 10,
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        colorScheme.brightness == Brightness.light
                            ? Colors.grey[200]
                            : Color(0xFF2C2C2C),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: Text(
                          'メーカーの割合',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 270,
                        child: PieChart(makerPieChartData()),
                      ),
                      Container(
                        height: 70,
                        alignment: Alignment.center,
                        child: Text(
                          'アイテム数TOP5',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 300, child: buildTop5MakerList()),
                    ],
                  ),
                ),
                const SizedBox(height: 150),

                //_buildTitle('メーカー別（トップ5）'),
                //SizedBox(height: 800, child: BarChart(makerBarChartData())),
              ],
            ),
          ),
          if (!_isPremium) ...[
            // ぼかし効果
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0.3), // 半透明オーバーレイ
              ),
            ),

            // 中央のプレミアム案内ウィンドウ
            Center(child: _buildPremiumDialog(context)),
          ],
        ],
      ),
    );
  }

  //====================
  //プレミアム購入ダイアログ
  //====================
  Widget _buildPremiumDialog(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'プレミアム会員専用機能',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '統計ページはプレミアム会員専用です。\n機能を使うにはアップグレードしてください。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              icon: const Icon(Icons.star, color: Colors.black),
              label: const Text(
                'プレミアムに登録',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              onPressed: () {
                _startPurchase();
              },
            ),
          ],
        ),
      ),
    );
  }

  //プレミアム購入処理
  void _startPurchase() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;

      if (offering != null && offering.availablePackages.isNotEmpty) {
        final package = offering.availablePackages.first;

        // 購入処理（PurchaseResultを受け取る）
        final purchaseResult = await Purchases.purchasePackage(package);

        // 最新のCustomerInfoを取得
        final customerInfo = await Purchases.getCustomerInfo();

        // RevenueCatのEntitlement IDを確認（例: "premium"）
        if (customerInfo.entitlements.all["Premium Plan"]?.isActive ?? false) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('プレミアムを購入しました！')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('購入は完了しましたが、プレミアムが有効化されませんでした')),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('購入可能なプランが見つかりません')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('購入エラー: $e')));
    }
  }

  Widget _buildTitle(String text) {
    final color = Theme.of(context).colorScheme.onPrimary;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  //==================
  //出演データ（円グラフ）
  //==================
  PieChartData castPieChartData() {
    final total = castCounts.values.fold(0, (a, b) => a + b);
    final sections =
        castCounts.entries.map((entry) {
          final percentage = entry.value / total;
          return PieChartSectionData(
            title: '${entry.key} (${(percentage * 100).toStringAsFixed(1)}%)',
            value: entry.value.toDouble(),
            color:
                Colors.primaries[castCounts.keys.toList().indexOf(entry.key) %
                    Colors.primaries.length],
            radius: 130,
            titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
          );
        }).toList();

    return PieChartData(
      sections: sections,
      centerSpaceRadius: 0,
      sectionsSpace: 2,
    );
  }

  Widget buildTop5CastList() {
    final sortedEntries =
        castCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // 降順ソート

    final top5 = sortedEntries.take(5).toList(); // 上位5件を取得
    final total = castCounts.values.fold(0, (a, b) => a + b); // 合計数

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // 必要に応じて調整
      itemCount: top5.length,
      itemBuilder: (context, index) {
        final entry = top5[index];
        final percentage = (entry.value / total) * 100;

        final colorIndex =
            castCounts.keys.toList().indexOf(entry.key) %
            Colors.primaries.length;
        final color = Colors.primaries[colorIndex];

        return ListTile(
          leading: CircleAvatar(backgroundColor: color),
          title: Text(
            entry.key,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            '${percentage.toStringAsFixed(1)}% (${entry.value}件)',
            style: TextStyle(fontSize: 18),
          ),
        );
      },
    );
  }

  //ジャンルデータ（円グラフ）
  PieChartData genrePieChartData() {
    final total = genreCounts.values.fold(0, (a, b) => a + b);
    final sections =
        genreCounts.entries.map((entry) {
          final percentage = entry.value / total;
          return PieChartSectionData(
            title: '${entry.key} (${(percentage * 100).toStringAsFixed(1)}%)',
            value: entry.value.toDouble(),
            color:
                Colors.primaries[genreCounts.keys.toList().indexOf(entry.key) %
                    Colors.primaries.length],
            radius: 130,
            titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
          );
        }).toList();

    return PieChartData(
      sections: sections,
      centerSpaceRadius: 0,
      sectionsSpace: 2,
    );
  }

  Widget buildTop5GenreList() {
    final sortedEntries =
        genreCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // 降順ソート

    final top5 = sortedEntries.take(5).toList(); // 上位5件を取得
    final total = genreCounts.values.fold(0, (a, b) => a + b); // 合計数

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // 必要に応じて調整
      itemCount: top5.length,
      itemBuilder: (context, index) {
        final entry = top5[index];
        final percentage = (entry.value / total) * 100;

        final colorIndex =
            genreCounts.keys.toList().indexOf(entry.key) %
            Colors.primaries.length;
        final color = Colors.primaries[colorIndex];

        return ListTile(
          leading: CircleAvatar(backgroundColor: color),
          title: Text(
            entry.key,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            '${percentage.toStringAsFixed(1)}% (${entry.value}件)',
            style: TextStyle(fontSize: 18),
          ),
        );
      },
    );
  }

  //シリーズデータ（円グラフ）
  PieChartData seriesPieChartData() {
    final total = seriesCounts.values.fold(0, (a, b) => a + b);
    final sections =
        seriesCounts.entries.map((entry) {
          final percentage = entry.value / total;
          return PieChartSectionData(
            title: '${entry.key} (${(percentage * 100).toStringAsFixed(1)}%)',
            value: entry.value.toDouble(),
            color:
                Colors.primaries[seriesCounts.keys.toList().indexOf(entry.key) %
                    Colors.primaries.length],
            radius: 130,
            titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
          );
        }).toList();

    return PieChartData(
      sections: sections,
      centerSpaceRadius: 0,
      sectionsSpace: 2,
    );
  }

  Widget buildTop5SeriesList() {
    final sortedEntries =
        seriesCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // 降順ソート

    final top5 = sortedEntries.take(5).toList(); // 上位5件を取得
    final total = seriesCounts.values.fold(0, (a, b) => a + b); // 合計数

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // 必要に応じて調整
      itemCount: top5.length,
      itemBuilder: (context, index) {
        final entry = top5[index];
        final percentage = (entry.value / total) * 100;

        final colorIndex =
            seriesCounts.keys.toList().indexOf(entry.key) %
            Colors.primaries.length;
        final color = Colors.primaries[colorIndex];

        return ListTile(
          leading: CircleAvatar(backgroundColor: color),
          title: Text(
            entry.key,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            '${percentage.toStringAsFixed(1)}% (${entry.value}件)',
            style: TextStyle(fontSize: 18),
          ),
        );
      },
    );
  }

  //レーベルデータ（円グラフ）
  PieChartData labelPieChartData() {
    final total = labelCounts.values.fold(0, (a, b) => a + b);
    final sections =
        labelCounts.entries.map((entry) {
          final percentage = entry.value / total;
          return PieChartSectionData(
            title: '${entry.key} (${(percentage * 100).toStringAsFixed(1)}%)',
            value: entry.value.toDouble(),
            color:
                Colors.primaries[labelCounts.keys.toList().indexOf(entry.key) %
                    Colors.primaries.length],
            radius: 130,
            titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
          );
        }).toList();

    return PieChartData(
      sections: sections,
      centerSpaceRadius: 0,
      sectionsSpace: 2,
    );
  }

  Widget buildTop5LabelList() {
    final sortedEntries =
        labelCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // 降順ソート

    final top5 = sortedEntries.take(5).toList(); // 上位5件を取得
    final total = labelCounts.values.fold(0, (a, b) => a + b); // 合計数

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // 必要に応じて調整
      itemCount: top5.length,
      itemBuilder: (context, index) {
        final entry = top5[index];
        final percentage = (entry.value / total) * 100;

        final colorIndex =
            labelCounts.keys.toList().indexOf(entry.key) %
            Colors.primaries.length;
        final color = Colors.primaries[colorIndex];

        return ListTile(
          leading: CircleAvatar(backgroundColor: color),
          title: Text(
            entry.key,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            '${percentage.toStringAsFixed(1)}% (${entry.value}件)',
            style: TextStyle(fontSize: 18),
          ),
        );
      },
    );
  }

  //メーカーデータ（円グラフ）
  PieChartData makerPieChartData() {
    final total = makerCounts.values.fold(0, (a, b) => a + b);
    final sections =
        makerCounts.entries.map((entry) {
          final percentage = entry.value / total;
          return PieChartSectionData(
            title: '${entry.key} (${(percentage * 100).toStringAsFixed(1)}%)',
            value: entry.value.toDouble(),
            color:
                Colors.primaries[makerCounts.keys.toList().indexOf(entry.key) %
                    Colors.primaries.length],
            radius: 130,
            titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
          );
        }).toList();

    return PieChartData(
      sections: sections,
      centerSpaceRadius: 0,
      sectionsSpace: 2,
    );
  }

  Widget buildTop5MakerList() {
    final sortedEntries =
        makerCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // 降順ソート

    final top5 = sortedEntries.take(5).toList(); // 上位5件を取得
    final total = makerCounts.values.fold(0, (a, b) => a + b); // 合計数

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // 必要に応じて調整
      itemCount: top5.length,
      itemBuilder: (context, index) {
        final entry = top5[index];
        final percentage = (entry.value / total) * 100;

        final colorIndex =
            makerCounts.keys.toList().indexOf(entry.key) %
            Colors.primaries.length;
        final color = Colors.primaries[colorIndex];

        return ListTile(
          leading: CircleAvatar(backgroundColor: color),
          title: Text(
            entry.key,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            '${percentage.toStringAsFixed(1)}% (${entry.value}件)',
            style: TextStyle(fontSize: 18),
          ),
        );
      },
    );
  }

  BarChartData makerBarChartData() {
    final sorted =
        makerCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    return BarChartData(
      barGroups: List.generate(top5.length, (i) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: top5[i].value.toDouble(),
              color: Colors.teal,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              final label = top5[value.toInt()].key;
              return Text(label, style: const TextStyle(fontSize: 8));
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 30),
        ),
      ),
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: false),
    );
  }

  //============================
  //評価の統計
  //============================
  //評価毎のグラフデータ
  PieChartData ratingPieChartData() {
    // データセット（未評価も含む）
    final ratingMap = {
      'critical': ratingCounts['critical'] ?? 0,
      'normal': ratingCounts['normal'] ?? 0,
      'maniac': ratingCounts['maniac'] ?? 0,
      'unrated': ratingCounts['unrated'] ?? 0, // 未評価も集計されている想定
    };

    final total = ratingMap.values.fold(0, (a, b) => a + b) + 1;
    if (total == 0) {
      return PieChartData(sections: []);
    }

    final labelsJP = {
      'critical': 'クリティカル',
      'normal': 'ノーマル',
      'maniac': 'マニアック',
      'unrated': '未評価',
    };

    final colors = {
      'critical': Colors.red,
      'normal': Colors.yellow[700]!,
      'maniac': Colors.purple,
      'unrated': Colors.grey,
    };

    final sections =
        ratingMap.entries.where((e) => e.value > 0).map((entry) {
          final key = entry.key;
          final count = entry.value;
          final percentage = (count / total) * 100;
          return PieChartSectionData(
            value: count.toDouble(),
            title: '${labelsJP[key]} (${percentage.toStringAsFixed(1)}%)',
            color: colors[key],
            radius: 130,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
          );
        }).toList();

    return PieChartData(
      sections: sections,
      centerSpaceRadius: 0,
      sectionsSpace: 2,
    );
  }

  //評価ごとの視聴回数集計
  Map<String, int> viewingCountByRating = {
    'critical': 0,
    'normal': 0,
    'maniac': 0,
    'unrated': 0,
  };

  //視聴回数の集計
  Future<void> _loadViewingCountByRating() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('saved_metadata') ?? [];

    final Map<String, int> tempMap = {
      'critical': 0,
      'normal': 0,
      'maniac': 0,
      'unrated': 0,
    };

    for (final item in savedList) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      final url = map['url']?.toString();
      if (url == null || url.isEmpty) continue;

      final rating = (map['rating'] ?? 'unrated').toString().toLowerCase();
      final validRating =
          ['critical', 'normal', 'maniac'].contains(rating)
              ? rating
              : 'unrated';

      final count = prefs.getInt(url) ?? 0;
      tempMap[validRating] = tempMap[validRating]! + count;
    }

    setState(() {
      viewingCountByRating = tempMap;
    });
  }

  //評価ごとの視聴回数合計（棒グラフ）
  BarChartData viewingCountBarChartData() {
    final colorScheme = Theme.of(context).colorScheme;
    final labels = ['critical', 'normal', 'maniac', 'unrated'];
    final colors = [Colors.red, Colors.yellow, Colors.purple, Colors.grey];
    final maxY =
        viewingCountByRating.values.reduce((a, b) => a > b ? a : b).toDouble() +
        1;

    final maxCount = ratingCounts.values.reduce((a, b) => a > b ? a : b);

    // グリッド線間隔を動的に決定
    double interval;
    if (maxCount < 6) {
      interval = 1;
    } else if (maxCount < 10) {
      interval = maxY;
    } else {
      interval = (maxY / 5).ceilToDouble(); // 約5本にする
    }

    //maxYより小さく補正
    if (interval >= maxY) {
      interval = maxY / 2;
    }

    //棒グラフデータ
    return BarChartData(
      maxY: maxY,
      barGroups: List.generate(labels.length, (i) {
        final label = labels[i];
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: viewingCountByRating[label]!.toDouble(),
              color: colors[i],
              width: 30,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              const jpLabels = ['クリティカル', 'ノーマル', 'マニアック', '未評価'];
              return Text(
                jpLabels[value.toInt()],
                style: const TextStyle(fontSize: 12),
              );
            },
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        //leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40, // 少し余白を確保
            getTitlesWidget: (value, meta) {
              if (value == 0) {
                // 左下の位置だけ「(回)」と表示
                return const Text('(回)', style: TextStyle(fontSize: 16));
              } else {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 16),
                );
              }
            },
          ),
        ),

        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true, // 横線を描画するか
        drawVerticalLine: false, // 縦線を描画するか（棒グラフでは通常false）
        //horizontalInterval: interval, // 横線の間隔（Y軸）
        horizontalInterval: null, //自動調整
        verticalInterval: 1.0, // 縦線の間隔（X軸）
        getDrawingHorizontalLine:
            (value) => FlLine(
              color: colorScheme.onPrimary, // 線の色
              strokeWidth: 0.5, // 線の太さ
              dashArray: [1, 0], // 点線にする（省略可）
            ),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.black87, // 背景色（任意）
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${rod.toY.toInt()}回',
              TextStyle(
                color: Colors.white, // ← ここがtipの文字色
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }

  //==================
  //視聴数TOP5（棒グラフ）
  //==================
  Map<String, String> urlToTitleMap = {};
  Map<String, String> urlToImageMap = {};
  List<MapEntry<String, int>> top5Viewings = [];

  Future<void> _loadTop5ViewingStats() async {
    final prefs = await SharedPreferences.getInstance();

    // URL→視聴回数マップ
    final allKeys = prefs.getKeys();
    final viewCounts = <String, int>{};

    for (final key in allKeys) {
      final raw = prefs.get(key);
      if (raw is int && raw > 0 && key.startsWith('http')) {
        viewCounts[key] = raw;
      }
    }

    // URL→タイトルのマップ
    final savedList = prefs.getStringList('saved_metadata') ?? [];
    for (final item in savedList) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      final url = map['url']?.toString();
      final title = map['title']?.toString();
      final image = map['image']?.toString();
      if (url != null && title != null) {
        urlToTitleMap[url] = title;
        if (image != null) {
          urlToImageMap[url] = image; // ← 追加
        }
      }
    }

    // トップ5抽出（視聴回数順）
    final sorted =
        viewCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    top5Viewings = sorted.take(5).toList();

    setState(() {});
  }

  BarChartData top5ViewingBarChartData() {
    final colorScheme = Theme.of(context).colorScheme;
    final maxY =
        top5Viewings
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .toDouble() +
        1;

    return BarChartData(
      maxY: maxY,
      barGroups: List.generate(top5Viewings.length, (i) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: top5Viewings[i].value.toDouble(),
              color: Colors.blueAccent,
              width: 30,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              final index = value.toInt();
              if (index < 0 || index >= top5Viewings.length)
                return const SizedBox();

              final url = top5Viewings[value.toInt()].key;
              final imageUrl = urlToImageMap[url];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child:
                        imageUrl != null
                            ? Image.network(
                              imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 40),
                            )
                            : const Icon(Icons.image_not_supported, size: 40),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _shortenTitle(urlToTitleMap[url] ?? 'タイトルなし'),
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, _) {
              if (value == 0) {
                return const Text('(回)', style: TextStyle(fontSize: 12));
              } else {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              }
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false, // 縦線を描画するか（棒グラフでは通常false）
        horizontalInterval: (maxY / 5).ceilToDouble(),
        getDrawingHorizontalLine:
            (value) => FlLine(color: colorScheme.onPrimary, strokeWidth: 0.5),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.black87, // 背景色（任意）
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${rod.toY.toInt()}回',
              TextStyle(
                color: Colors.white, // ← ここがtipの文字色
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }

  //タイトルを短くするメソッド（長すぎるタイトル対策）
  String _shortenTitle(String title, {int maxLength = 7}) {
    return title.length <= maxLength
        ? title
        : '${title.substring(0, maxLength)}...';
  }
}
