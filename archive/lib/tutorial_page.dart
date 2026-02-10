import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'main_page.dart';

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

class TutorialOverlayPseudoTap extends StatelessWidget {
  final Rect holeRect;
  final VoidCallback onTap;

  const TutorialOverlayPseudoTap({
    super.key,
    required this.holeRect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
