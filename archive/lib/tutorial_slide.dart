import 'package:flutter/material.dart';

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

  final slides = [
    IntroSlide(
      title: "ダウンロード不要の\n動画管理アプリ",
      desc: "容量を使わず好きなだけ動画を収集",
      image: "assets/tutorial/Japanese01.png",
    ),
    IntroSlide(
      title: "【簡単2ステップ】\n①URLをコピー",
      desc: "動画サイトの共有リンクやブラウザのURLをコピー",
      image: "assets/tutorial/Japanese02.png",
    ),
    IntroSlide(
      title: "【簡単2ステップ】\n②コピーしたURLを保存",
      desc: "貼るだけで登録\n評価・タグ・メモも追加可能",
      image: "assets/tutorial/Japanese03.png",
    ),
    IntroSlide(
      title: "アプリ内検索",
      desc: "保存した動画がタイトル・タグですぐ見つかる。",
      image: "assets/tutorial/Japanese04.png",
    ),
    IntroSlide(
      title: "ウェブ検索",
      desc: "アプリ内ブラウザで、探してすぐに保存",
      image: "assets/tutorial/Japanese05.png",
    ),
    IntroSlide(
      title: "可能性は無限大",
      desc: "自分だけの動画コレクションを作ろう！",
      image: "assets/tutorial/Japanese06.png",
    ),
  ];

  void next() {
    if (index == slides.length - 1) {
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// スライド
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => index = i),
                itemBuilder: (_, i) {
                  final slide = slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "STEP ${i + 1}/${slides.length}",
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
                            fontSize: i == slides.length - 1 ? 30 : 26,
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
                slides.length,
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
                    index == slides.length - 1 ? "開始する" : "次へ",
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
