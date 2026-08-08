import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Tracks device connectivity so screens can show an offline banner and avoid
/// triggering sync work while the network is down.
class ConnectivityController extends GetxController {
  static ConnectivityController get to => Get.find<ConnectivityController>();

  /// True when at least one transport (wifi/mobile/ethernet) is available.
  final RxBool isOnline = RxBool(true);

  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    final connectivity = Connectivity();
    try {
      final results = await connectivity.checkConnectivity();
      _apply(results);
    } catch (_) {
      // Plugin unavailable (tests/unsupported) — stay online.
    }
    try {
      _sub = connectivity.onConnectivityChanged.listen(_apply);
    } catch (_) {
      // Listeners may be unsupported on some platforms; ignore.
    }
  }

  void _apply(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (isOnline.value != online) isOnline.value = online;
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
