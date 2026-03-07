import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preference_app_group/shared_preference_app_group.dart';

import 'theme_provider.dart';
import 'launch_gate.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();

  final container = ProviderContainer();
  await container.read(themeModeProvider.notifier).loadTheme();
  await container.read(themeColorProvider.notifier).loadColor();

  // トラッキング許可ダイアログ
  //final status = await AppTrackingTransparency.requestTrackingAuthorization();

  // AdMobの初期化処理
  await MobileAds.instance.initialize();

  final apiKey =
      Platform.isAndroid
          ? "goog_ynrVimxZpjIrMuoZAHIgIotPSQk"
          : "appl_kKWivbmxqAEXEBqUmLeiUoAyyRN";

  //RevenueCat を初期化
  await Purchases.configure(PurchasesConfiguration(apiKey));

  await SharedPreferenceAppGroup.setAppGroup(
    "group.com.walkinggoblins.archive",
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    AppRestart(
      child: UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _waitForInitialization();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 200));
      checkShare();
    });
  }

  //アプリ復帰通知
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkShare();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool removed = false;

  Future<void> _waitForInitialization() async {
    // ここではあえてディレイを入れることで、初期描画前の安定化を図ります。
    await Future.delayed(const Duration(milliseconds: 20));
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // テーマの読み込みが完了するまで、プレースホルダーを表示
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(themeModeProvider);
        final themeColor = ref.watch(themeColorProvider);

        return MaterialApp(
          debugShowCheckedModeBanner: false,

          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return supportedLocales.first;
            return supportedLocales.firstWhere(
              (supported) => supported.languageCode == locale.languageCode,
              orElse: () => supportedLocales.first,
            );
          },

          theme: getThemeData(themeColor, false),
          darkTheme: getThemeData(themeColor, true),
          themeMode: themeMode,
          home: const LaunchGate(),
        );
      },
    );
  }

  void checkShare() async {
    final url = await getSharedURL();

    if (url != null) {
      print("Shared URL: $url");

      await saveUrlAuto(url);
    }
  }

  Future<String?> getSharedURL() async {
    final url = await SharedPreferenceAppGroup.getString("shared_url");

    if (url != null) {
      await SharedPreferenceAppGroup.remove("shared_url");
    }

    return url;
  }

  //タイトル取得
  Future<String?> fetchTitleFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final titleTag = document.getElementsByTagName('title');

        if (titleTag.isNotEmpty) {
          return titleTag.first.text.trim();
        }
      }
    } catch (e) {
      print("title fetch error: $e");
    }

    return null;
  }

  //サムネを取得
  Future<String?> fetchThumbnailByWebView(String url) async {
    final Completer<String?> completer = Completer();

    // Invisible WebView を作る
    final InAppWebView webView = InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          javaScriptEnabled: true,
          transparentBackground: true,
        ),
      ),
      onLoadStop: (controller, uri) async {
        try {
          final js = """
          (function() {
            var og = document.querySelector('meta[property="og:image"]');
            if (og && og.content) return og.content;

            var item = document.querySelector('meta[itemprop="image"]');
            if (item && item.content) return item.content;

            var video = document.querySelector('video');
            if (video && video.poster) return video.poster;

            var link = document.querySelector('link[rel="image_src"]');
            if (link && link.href) return link.href;

            var imgs = document.querySelectorAll('img');
            for (var i = 0; i < imgs.length; i++) {
              var s = imgs[i].src;
              if (s.includes("/wp-content/uploads")) return s;
            }

            var img = document.querySelector('img');
            if (img && img.src) return img.src;

            return null;
          })();
        """;

          final result = await controller.evaluateJavascript(source: js);

          if (!completer.isCompleted) {
            if (result == null || result == "null") {
              completer.complete(null);
            } else {
              String resolved =
                  Uri.parse(url).resolve(result.toString()).toString();
              completer.complete(resolved);
            }
          }
        } catch (_) {
          if (!completer.isCompleted) completer.complete(null);
        }
      },
    );

    // WebView を非表示で画面に追加する
    OverlayEntry entry = OverlayEntry(
      builder: (_) {
        return Positioned(
          left: 0,
          top: 0,
          width: 1,
          height: 1,
          child: Opacity(opacity: 0.0, child: webView),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(entry);

    void safeRemove() {
      if (!removed) {
        removed = true;
        entry.remove();
      }
    }

    // タイムアウト 10秒
    return completer.future
        .timeout(
          Duration(seconds: 30),
          onTimeout: () {
            safeRemove();
            return null;
          },
        )
        .whenComplete(() {
          safeRemove();
        });
  }

  //自動保存
  Future<void> saveUrlAuto(String url) async {
    final prefs = await SharedPreferences.getInstance();

    final results = await Future.wait([
      fetchTitleFromUrl(url),
      fetchThumbnailByWebView(url),
    ]);

    final title = results[0];
    final thumbnail = results[1];

    final data = {
      'listName': '',
      'url': url,
      'title': title ?? '',
      'image': thumbnail ?? '',
      'cast': '',
      'genre': '',
      'series': '',
      'label': '',
      'maker': '',
      'memo': '',
      'rating': 'unrated',
    };

    final savedList = prefs.getStringList('saved_metadata') ?? [];
    final updatedList = <String>[];

    bool found = false;

    for (final item in savedList) {
      final map = jsonDecode(item) as Map<String, dynamic>;

      if (map['url'] == url) {
        updatedList.add(jsonEncode(data));
        found = true;
      } else {
        updatedList.add(item);
      }
    }

    if (!found) {
      updatedList.add(jsonEncode(data));
    }

    await prefs.setStringList('saved_metadata', updatedList);

    print("saved complete");
  }
}

class AppRestart extends StatefulWidget {
  final Widget child;
  const AppRestart({super.key, required this.child});

  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_AppRestartState>()?.restart();
  }

  @override
  State<AppRestart> createState() => _AppRestartState();
}

class _AppRestartState extends State<AppRestart> {
  Key _key = UniqueKey();

  void restart() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
