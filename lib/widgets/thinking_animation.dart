import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ThinkingAnimation extends StatelessWidget {
  const ThinkingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
                delay: Duration(milliseconds: index * 140),
              )
              .moveY(
                begin: 0,
                end: -8,
                duration: 520.ms,
                curve: Curves.easeInOut,
              ),
        );
      }),
    );
  }
}
