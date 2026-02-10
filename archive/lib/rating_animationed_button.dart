import 'package:flutter/material.dart';

//現在未使用のクラス

enum RatingAnimationStyle { critical, normal, maniac }

class RatingAnimatedButton extends StatefulWidget {
  final String imagePath;
  final String grayPath;
  final bool isSelected;
  final VoidCallback onTap;
  final RatingAnimationStyle style;

  const RatingAnimatedButton({
    super.key,
    required this.imagePath,
    required this.grayPath,
    required this.isSelected,
    required this.onTap,
    required this.style,
  });

  @override
  State<RatingAnimatedButton> createState() => _RatingAnimatedButtonState();
}

class _RatingAnimatedButtonState extends State<RatingAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    switch (widget.style) {
      case RatingAnimationStyle.critical:
        _scale = TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.95), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        );

        _rotation = Tween<double>(
          begin: -0.12,
          end: 0.0,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
        break;

      case RatingAnimationStyle.normal:
        _scale = TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
        ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

        _rotation = AlwaysStoppedAnimation(0);
        break;

      case RatingAnimationStyle.maniac:
        _scale = TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 70),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        );

        _rotation = Tween<double>(begin: -0.25, end: 0.25).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticInOut),
        );
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!widget.isSelected) {
      await _controller.forward(from: 0);
    }

    if (!mounted) return;
    _controller.reset();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Transform.scale(
            scale: _scale.value,
            child: Transform.rotate(
              angle: _rotation.value,
              child: Image.asset(
                widget.isSelected ? widget.imagePath : widget.grayPath,
                width: 40,
                height: 40,
              ),
            ),
          );
        },
      ),
    );
  }
}
