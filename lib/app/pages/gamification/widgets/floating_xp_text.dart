import 'package:flutter/material.dart';

class FloatingXpText extends StatefulWidget {
  final String text;
  const FloatingXpText({super.key, required this.text});

  @override
  State<FloatingXpText> createState() => _FloatingXpTextState();
}

class _FloatingXpTextState extends State<FloatingXpText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Text(
          widget.text,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
