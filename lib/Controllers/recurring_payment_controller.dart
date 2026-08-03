import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:money_control/Models/recurring_payment_model.dart';
import 'package:money_control/Services/cache_service.dart';
import 'package:money_control/Services/recurring_service.dart';

class RecurringPaymentController extends GetxController {
  static RecurringPaymentController get to => Get.find();

  final RecurringService _service = RecurringService();
  final _auth = FirebaseAuth.instance;
  final RxDouble pendingSubscriptions = 0.0.obs;
  StreamSubscription<List<RecurringPayment>>? _paymentsSub;

  String? get _userEmail => _auth.currentUser?.email;
  String get _cacheKey => 'recurring_${_userEmail ?? ''}';

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
    _fetchFromFirestore();
    // Keep the monthly commitment in lockstep with the subscriptions screen:
    // recompute on every Firestore snapshot so adds/edits/deletes and auto-pay
    // date advances are reflected without restarting the app.
    _paymentsSub = _service.getPayments().listen(
      (list) => pendingSubscriptions.value = _computeMonthlyTotal(list),
      onError: (e) => log('RecurringPaymentController stream error: $e'),
    );
  }

  @override
  void onClose() {
    _paymentsSub?.cancel();
    super.onClose();
  }

  void _loadFromCache() {
    final cached = LocalCacheService.get(_cacheKey);
    if (cached is List) {
      final list = cached.map((e) {
        final map = LocalCacheService.hiveRestore(Map<String, dynamic>.from(e as Map));
        final id = map.remove('_id') as String? ?? '';
        return RecurringPayment.fromMap(id, map);
      }).toList();
      pendingSubscriptions.value = _computeMonthlyTotal(list);
    }
  }

  Future<void> _fetchFromFirestore() async {
    try {
      // Foreground auto-pay: process due auto-pay payments right away so the
      // transaction + date advance work on web (no WorkManager) and faster
      // than the 15-min background worker. Pending (non-auto-pay) payments are
      // returned but intentionally ignored here — the reminder is sent only
      // from the background worker to avoid notifying while the user is in-app.
      final email = _auth.currentUser?.email;
      final uid = _auth.currentUser?.uid;
      if (email != null && uid != null) {
        await RecurringService.processDuePayments(email, uid);
      }

      final list = await _service.getPaymentsOnce();
      if (_userEmail != null) {
        final cacheData = list.map((t) {
          final map = t.toMap();
          map['_id'] = t.id;
          return LocalCacheService.hiveSafe(map);
        }).toList();
        LocalCacheService.put(_cacheKey, cacheData, ttl: LocalCacheService.slow5m);
      }
    } catch (e) {
      log('RecurringPaymentController._fetchFromFirestore error: $e');
    }
  }

  double _computeMonthlyTotal(List<RecurringPayment> payments) {
    double total = 0;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    for (var p in payments) {
      if (!p.isActive) continue;
      if (p.nextDueDate.year == now.year && p.nextDueDate.month == now.month) {
        total += p.amount;
      } else if (p.nextDueDate.isBefore(startOfMonth)) {
        total += p.amount;
      }
    }
    return total;
  }
}
