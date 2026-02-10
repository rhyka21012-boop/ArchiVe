import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_page.dart';
import 'tutorial_page.dart';

class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key});

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  bool? _isFirst;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFirst = prefs.getBool('isFirstLaunch') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirst == null) {
      return const SizedBox(); // Splash
    }

    if (_isFirst!) {
      return TutorialPage(onComplete: () => completeTutorial(context));
    }

    return const MainPage();
  }

  Future<void> completeTutorial(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));
  }
}
