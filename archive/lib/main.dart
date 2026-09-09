import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'launch_gate.dart';
import 'global_player_layer.dart';
import 'pip_helper.dart';
import 'download_ad_service.dart';
//import 'grid_view_native_ad_factory.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart';
import 'rating_label_provider.dart';

import 'l10n/app_localizations.dart';

/// アプリのルート Navigator への参照。
/// GlobalPlayerLayer など Navigator の外にあるレイヤーから、購入導線等の
/// ページを push する際に使用する。
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// アプリ全体で共有する ScaffoldMessenger 参照。
/// バックグラウンドタスク完了/失敗通知など、深いネスト以外の場所からも
/// SnackBar を表示できるようにする。
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final container = ProviderContainer();
  await container.read(themeModeProvider.notifier).loadTheme();
  await container.read(themeColorProvider.notifier).loadColor();
  await container.read(ratingLabelsProvider.notifier).load();

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

  // バックグラウンド音声のための AudioSession 初期化
  await PipHelper().ensureConfigured();

  // ダウンロード完了時インターステイシャル広告のプリロード
  DownloadAdService().preload();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

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

class _MyAppState extends State<MyApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _waitForInitialization();
  }

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
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: rootScaffoldMessengerKey,

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
          // 全ルート上にミニプレイヤーを重ねる (どの画面でも表示される)
          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                const Positioned.fill(child: GlobalPlayerLayer()),
              ],
            );
          },
        );
      },
    );
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
