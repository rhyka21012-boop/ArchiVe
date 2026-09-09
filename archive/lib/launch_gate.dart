import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tutorial_slide.dart';
import 'main_page.dart';
import 'tutorial_page.dart';
import 'consent_page.dart';

class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key});

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  bool? _isFirst;
  bool? _consented;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool('isFirstLaunch') ?? true;
    final consented = await isConsentAccepted();
    if (!mounted) return;
    setState(() {
      _isFirst = isFirst;
      _consented = consented;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirst == null || _consented == null) {
      return const SizedBox(); // Splash
    }

    // 免責/利用規約/プライバシーへの同意が未取得なら最初に見せる
    if (!_consented!) {
      return ConsentPage(
        onAccepted: () {
          setState(() => _consented = true);
        },
      );
    }

    if (_isFirst!) {
      return IntroScreen(
        onFinished: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (_) =>
                      TutorialPage(onComplete: () => completeTutorial(context)),
            ),
          );
        },
      );
    }

    return const MainPage();
  }

  Future<void> completeTutorial(BuildContext context) async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);

    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const PostTutorialPremiumPromptPage()),
    );
  }
}
