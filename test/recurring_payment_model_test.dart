import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_control/Models/recurring_payment_model.dart';

void main() {
  Map<String, dynamic> baseMap() => {
    'userId': 'u1',
    'title': 'Netflix',
    'amount': 499.0,
    'category': 'Entertainment',
    'frequency': 'monthly',
    'startDate': Timestamp.fromDate(DateTime(2026, 8, 1)),
    'nextDueDate': Timestamp.fromDate(DateTime(2026, 9, 1)),
    'isActive': true,
    'autoPay': true,
  };

  group('RecurringPayment autoPay defaults', () {
    test('constructor defaults autoPay to false (opt-in)', () {
      final p = RecurringPayment(
        id: '1',
        userId: 'u1',
        title: 'Netflix',
        amount: 499,
        category: 'Entertainment',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 8, 1),
        nextDueDate: DateTime(2026, 9, 1),
        isActive: true,
      );
      expect(p.autoPay, false);
    });

    test('legacy doc without autoPay field defaults to false (no auto-deduct)', () {
      final map = baseMap()..remove('autoPay');
      final p = RecurringPayment.fromMap('1', map);
      expect(p.autoPay, false);
      expect(p.isActive, true);
    });

    test('explicit autoPay: false is preserved', () {
      final p = RecurringPayment.fromMap('1', baseMap()..['autoPay'] = false);
      expect(p.autoPay, false);
    });

    test('explicit autoPay: true is preserved', () {
      final p = RecurringPayment.fromMap('1', baseMap());
      expect(p.autoPay, true);
    });

    test('toMap writes autoPay field', () {
      final p = RecurringPayment.fromMap('1', baseMap()..['autoPay'] = false);
      expect(p.toMap()['autoPay'], false);
    });
  });
}
