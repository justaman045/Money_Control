import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money_control/Services/performance_controller.dart';

/// Staggered fade + slide-in entrance used across Analytics/Insights cards.
///
/// Reacts to lite mode changes: while lite mode is on the child renders
/// statically (the controller stays idle — no ticks, no CPU), and when it is
/// toggled off the entrance animation plays. This keeps cards animating after
/// a manual Settings toggle instead of freezing the gate at first build.
class StaggeredSlideFade extends StatefulWidget {
  final Widget child;
  final int delay;

  const StaggeredSlideFade({super.key, required this.child, this.delay = 0});

  @override
  State<StaggeredSlideFade> createState() => _StaggeredSlideFadeState();
}

class _StaggeredSlideFadeState extends State<StaggeredSlideFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  StreamSubscription<bool>? _liteSub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    if (!PerformanceController.to.liteMode.value) {
      _play();
    }
    _liteSub = PerformanceController.to.liteMode.listen((lite) {
      if (!mounted) return;
      if (lite) {
        // Stop immediately so toggling lite mode on also halts tickers.
        _controller.stop();
      } else {
        _play();
      }
    });
  }

  void _play() {
    if (widget.delay == 0) {
      _controller.forward(from: 0);
    } else {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted && !PerformanceController.to.liteMode.value) {
          _controller.forward(from: 0);
        }
      });
    }
  }

  @override
  void dispose() {
    _liteSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (PerformanceController.to.liteMode.value) return widget.child;
      return FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(position: _slideAnim, child: widget.child),
      );
    });
  }
}
