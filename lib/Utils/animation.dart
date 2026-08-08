import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:money_control/Services/performance_controller.dart';

/// Builds a list item that animates only when not in lite mode. Keeps the call
/// site one line: `return animatedItem(tile, index);`
///
/// Wrapped in [Obx] so toggling lite mode off in Settings re-applies the
/// entrance animation to list items (they mount as animated on the next
/// rebuild).
Widget animatedItem(
  Widget child,
  int index, {
  int staggerMs = 50,
  int? delay,
  bool slide = false,
}) {
  return Obx(() {
    if (PerformanceController.to.liteMode.value) return child;
    var animation = child.animate().fadeIn(
      delay: (delay ?? index * staggerMs).ms,
    );
    if (slide) {
      animation = animation.slideY(
        begin: 0.2,
        end: 0,
        duration: 300.ms,
        curve: Curves.easeOut,
      );
    }
    return animation;
  });
}
