import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'main_page.dart';

/// チュートリアルをスキップしてホーム or 購入画面に遷移
Future<void> skipTutorial(BuildContext context, WidgetRef ref) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  ref.read(tutorialStepProvider.notifier).state = TutorialStep.none;
  ref.read(isTutorialModeProvider.notifier).state = false;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isFirstLaunch', false);

  if (!context.mounted) return;
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const PostTutorialPremiumPromptPage()),
    (_) => false,
  );
}

enum TutorialStep {
  createList, // ListPageでFABを押す
  tapList, // 作成したリストをタップ
  createItem, // GridPageでFABを押す
  inputUrl,
  fetchTitle,
  saveItem,
  done,
  none,
}

final tutorialStepProvider = StateProvider<TutorialStep>(
  (ref) => TutorialStep.none,
);

final isTutorialModeProvider = StateProvider<bool>((ref) => false);

//最後に追加したリスト名を保持する
final tutorialTargetListNameProvider = StateProvider<String?>((ref) => null);

class TutorialPage extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const TutorialPage({super.key, required this.onComplete});

  @override
  ConsumerState<TutorialPage> createState() => _TutorialPageState();
}

class PostTutorialPremiumPromptPage extends StatefulWidget {
  /// 追加手段の案内 ([TutorialAddMethodsPage]) を挟むかどうか。
  ///
  /// チュートリアルを最後までやり切った場合だけ true。
  /// スキップした利用者は読み飛ばしたい意思を示しているので出さない。
  final bool showAddMethods;

  const PostTutorialPremiumPromptPage({super.key, this.showAddMethods = false});

  @override
  State<PostTutorialPremiumPromptPage> createState() =>
      _PostTutorialPremiumPromptPageState();
}

class _PostTutorialPremiumPromptPageState
    extends State<PostTutorialPremiumPromptPage> {
  bool _didShowPremium = false;

  @override
  void initState() {
    super.initState();

    // チュートリアル後の課金導線は廃止。MainPage に遷移するだけにする。
    //
    // 完了直後だけは、その前に作品の追加手段をまとめて案内する。
    // ここを合流点にしているのは、完了の契機が detail_page と
    // launch_gate の 2 か所にあり、どちらも最後にこの画面へ来るため。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didShowPremium) return;
      _didShowPremium = true;
      final navigator = Navigator.of(context);
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => widget.showAddMethods
              ? TutorialAddMethodsPage(
                  onFinished: () => navigator.pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainPage()),
                  ),
                )
              : const MainPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const SizedBox.expand(),
    );
  }
}

class _TutorialPageState extends ConsumerState<TutorialPage> {
  @override
  void initState() {
    super.initState();

    // チュートリアル開始
    Future.microtask(() {
      ref.read(isTutorialModeProvider.notifier).state = true;
      ref.read(tutorialStepProvider.notifier).state = TutorialStep.createList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(tutorialStepProvider);

    if (step == TutorialStep.done) {
      return TutorialCompleteOverlay(
        onFinished: () {
          ref.read(isTutorialModeProvider.notifier).state = false;
          widget.onComplete();
        },
      );
    }

    // 通常は MainPage（上に Overlay が乗る）
    return const MainPage();
  }
}

class TutorialOverlayPseudoTap extends ConsumerWidget {
  final Rect holeRect;
  final VoidCallback onTap;

  const TutorialOverlayPseudoTap({
    super.key,
    required this.holeRect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // 半透明オーバーレイ + 穴
        CustomPaint(size: Size.infinite, painter: _HolePainter(holeRect)),

        // 穴の上の透明タップ領域
        Positioned(
          left: holeRect.left,
          top: holeRect.top,
          width: holeRect.width,
          height: holeRect.height,
          child: GestureDetector(
            onTap: onTap,
            child: Container(color: Colors.transparent),
          ),
        ),

        // スキップボタン（左上）
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: TextButton(
            onPressed: () => skipTutorial(context, ref),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              L10n.of(context)!.skip,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HolePainter extends CustomPainter {
  final Rect hole;

  _HolePainter(this.hole);

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    final holePaint = Paint()..blendMode = BlendMode.clear;

    canvas.drawRRect(
      RRect.fromRectAndRadius(hole.inflate(8), const Radius.circular(32)),
      holePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TutorialCompleteOverlay extends StatefulWidget {
  final VoidCallback onFinished;

  const TutorialCompleteOverlay({required this.onFinished, super.key});

  @override
  State<TutorialCompleteOverlay> createState() =>
      _TutorialCompleteOverlayState();
}

class _TutorialCompleteOverlayState extends State<TutorialCompleteOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 3000), () {
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      ignoring: true,
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 72,
                    ),
                    SizedBox(height: 16),
                    Text(
                      L10n.of(context)!.completed_tutorial,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// チュートリアルを終えた直後に、作品の追加手段をまとめて案内する画面。
///
/// 対話形式のチュートリアルで通るのは「リストを作って URL から追加」の
/// 一本道だけなので、共有メニューやブラウザからの追加は知られないまま
/// 終わってしまう。最後にここで伝える。
class TutorialAddMethodsPage extends StatelessWidget {
  final VoidCallback onFinished;

  const TutorialAddMethodsPage({super.key, required this.onFinished});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // 端末が小さい / 文字サイズが大きい場合でも読めるようにする
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(Icons.auto_awesome, size: 52, color: cs.primary),
                      const SizedBox(height: 20),
                      Text(
                        l.tutorial_tips_title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _tip(
                        cs,
                        Icons.share_outlined,
                        l.tutorial_tips_share_title,
                        l.tutorial_tips_share_desc,
                      ),
                      const SizedBox(height: 14),
                      _tip(
                        cs,
                        Icons.bookmark_add_outlined,
                        l.tutorial_tips_browser_title,
                        l.tutorial_tips_browser_desc,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        l.tutorial_tips_footer,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onFinished,
                  child: Text(
                    l.tutorial_tips_start,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 追加手段 1 件分のカード
  Widget _tip(ColorScheme cs, IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, size: 22, color: cs.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
