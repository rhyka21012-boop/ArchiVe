import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class IntroSlide {
  final String title;
  final String desc;
  final String image;

  IntroSlide({required this.title, required this.desc, required this.image});
}

class TutorialScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const TutorialScreen({required this.onFinished, super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController controller = PageController();
  int index = 0;

  List<IntroSlide> slides(BuildContext context) {
    final l10n = L10n.of(context)!;

    return [
      IntroSlide(
        title: l10n.tutorial_slide_title_01,
        desc: l10n.tutorial_slide_dict_01,
        image: l10n.tutorial_slide_image_01,
      ),
      IntroSlide(
        title: l10n.tutorial_slide_title_02,
        desc: l10n.tutorial_slide_dict_02,
        image: l10n.tutorial_slide_image_02,
      ),
      IntroSlide(
        title: l10n.tutorial_slide_title_03,
        desc: l10n.tutorial_slide_dict_03,
        image: l10n.tutorial_slide_image_03,
      ),
      IntroSlide(
        title: l10n.tutorial_slide_title_04,
        desc: l10n.tutorial_slide_dict_04,
        image: l10n.tutorial_slide_image_04,
      ),
      IntroSlide(
        title: l10n.tutorial_slide_title_05,
        desc: l10n.tutorial_slide_dict_05,
        image: l10n.tutorial_slide_image_05,
      ),
      IntroSlide(
        title: l10n.tutorial_slide_title_06,
        desc: l10n.tutorial_slide_dict_06,
        image: l10n.tutorial_slide_image_06,
      ),
    ];
  }

  void next() {
    final total = slides(context).length;

    if (index == total - 1) {
      widget.onFinished();
    } else {
      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = L10n.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// スライド
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: slides(context).length,
                onPageChanged: (i) => setState(() => index = i),
                itemBuilder: (_, i) {
                  final slide = slides(context)[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "STEP ${i + 1}/${slides(context).length}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: i == slides(context).length - 1 ? 30 : 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Expanded(
                          child: Image.asset(slide.image, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          slide.desc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),

            /// インジケーター
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides(context).length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  width: index == i ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == i ? Colors.black : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 次へボタン
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all(0),
                    backgroundColor: MaterialStateProperty.all(
                      colorScheme.primary,
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  onPressed: next,
                  child: Text(
                    index == slides(context).length - 1
                        ? l10n.tutorial_slide_start
                        : l10n.tutorial_slide_next,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class IntroScreen extends StatelessWidget {
  final VoidCallback onFinished;
  const IntroScreen({required this.onFinished, super.key});

  @override
  Widget build(BuildContext context) {
    return TutorialScreen(onFinished: onFinished);
  }
}
