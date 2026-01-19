import 'package:flutter/material.dart';
import 'main_page.dart';
//import 'grid_view_native_ad_factory.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; //AdMob用のライブラリをインポート
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

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

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
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
        final colorName = ref.watch(themeColorProvider);

        Color primaryColor;
        switch (colorName) {
          case 'グリーン':
            primaryColor = Colors.lightGreen;
            break;
          case 'ブルー':
            primaryColor = Colors.lightBlue;
            break;
          case 'ホワイト':
            primaryColor = Colors.grey;
            break;
          case 'レッド':
            primaryColor = Colors.red;
            break;
          case 'イエロー':
            primaryColor = Colors.yellow[600]!;
            break;
          case 'オレンジ':
          default:
            primaryColor = Colors.orange[600]!;
            break;
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'NotoSansJP',
            colorScheme: ColorScheme.light(
              brightness: Brightness.light,
              surface: Colors.white,
              secondary: Colors.white,
              primary: primaryColor,
              onPrimary: Colors.black,
            ),
            appBarTheme: const AppBarTheme(
              iconTheme: IconThemeData(color: Colors.black),
            ),
          ),
          darkTheme: ThemeData(
            fontFamily: 'NotoSansJP',
            colorScheme: ColorScheme.dark(
              brightness: Brightness.dark,
              surface: Color(0xFF121212),
              secondary: Color(0xFF2C2C2C),
              //primary: Colors.orange[600]!,
              primary: primaryColor,
              onPrimary: Colors.white,
            ),
            //appBarTheme: const AppBarTheme(
            //  iconTheme: IconThemeData(color: Colors.white),
            //),
          ),
          themeMode: themeMode,
          home: const MainPage(),
        );
      },
    );
  }
}
