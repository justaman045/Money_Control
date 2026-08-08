import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global performance tier used to disable the most expensive rendering work
/// (BackdropFilter blur, staggered animations, shimmer/confetti, heavy
/// shadows) on low-end devices so the app stays smooth under constrained
/// CPU/GPU resources.
///
/// Auto-detected at startup (low core count ⇒ lite mode) and overridable from
/// Settings. Consumers should read [liteMode] inside an [Obx] or check it once
/// per build.
class PerformanceController extends GetxController {
  static PerformanceController get to => Get.find<PerformanceController>();

  static const _overrideKey = 'lite_mode_override';

  /// True when heavy visuals should be skipped.
  final RxBool liteMode = RxBool(false);

  /// True when the user manually pinned the tier (auto-detect bypassed).
  final RxBool userOverridden = RxBool(false);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getBool(_overrideKey);
    if (override != null) {
      userOverridden.value = true;
      liteMode.value = override;
      return;
    }
    liteMode.value = _autoDetect();
  }

  /// Conservative heuristic: 4 or fewer CPU cores ⇒ low-end device.
  bool _autoDetect() {
    if (kIsWeb) return false;
    return Platform.numberOfProcessors <= 4;
  }

  Future<void> setLiteMode(bool value) async {
    liteMode.value = value;
    userOverridden.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_overrideKey, value);
  }

  /// Re-enable auto-detection (clears the manual override).
  Future<void> resetToAuto() async {
    userOverridden.value = false;
    liteMode.value = _autoDetect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_overrideKey);
  }
}
