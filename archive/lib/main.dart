import 'package:flutter/material.dart';
import 'launch_gate.dart';
//import 'grid_view_native_ad_factory.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; //AdMob用のライブラリをインポート
import 'package:purchases_flutter/purchases_flutter.dart';
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

  //RevenueCat を初期化
  await Purchases.configure(
    PurchasesConfiguration("appl_kKWivbmxqAEXEBqUmLeiUoAyyRN"),
  );
  //runApp(MyApp());

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
    await Future.delayed(const Duration(milliseconds: 50));
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
