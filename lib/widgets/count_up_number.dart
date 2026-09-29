import 'package:flutter/material.dart';

class CountUpNumber extends StatelessWidget {
  final int targetNumber;
  final Duration duration;
  final TextStyle? style;

  const CountUpNumber({
    super.key,
    required this.targetNumber,
    this.duration = const Duration(milliseconds: 850),
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetNumber.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          value.round().toString(),
          style: style ??
              const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE65100),
              ),
        );
      },
    );
  }
}
