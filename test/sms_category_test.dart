import 'package:flutter_test/flutter_test.dart';
import 'package:money_control/Services/sms_service.dart';

void main() {
  const utilitiesRules = {
    'Utilities': ['mobile', 'bill', 'recharge'],
    'Food': ['zomato', 'swiggy'],
    'Travel': ['uber'],
  };

  group('SmsService.categorizeWith', () {
    test('user correction beats body keyword match', () {
      final category = SmsService.categorizeWith(
        merchant: 'riya',
        body: 'Rs 500 debited to riya for mobile recharge',
        rules: utilitiesRules,
        corrections: {'riya': 'Car'},
      );
      expect(category, 'Car');
    });

    test('user correction beats merchant keyword match', () {
      final category = SmsService.categorizeWith(
        merchant: 'zomato',
        body: 'paid to zomato via upi',
        rules: utilitiesRules,
        corrections: {'zomato': 'Shopping'},
      );
      expect(category, 'Shopping');
    });

    test('history beats body keyword match', () {
      final category = SmsService.categorizeWith(
        merchant: 'riya',
        body: 'paid to riya for mobile recharge',
        rules: utilitiesRules,
        history: {'riya': 'Car'},
      );
      expect(category, 'Car');
    });

    test('exact correction match returns the corrected category', () {
      final category = SmsService.categorizeWith(
        merchant: 'riya',
        body: 'paid to riya',
        rules: utilitiesRules,
        corrections: {'riya': 'Car'},
      );
      expect(category, 'Car');
    });

    test('substring correction match returns the corrected category', () {
      final category = SmsService.categorizeWith(
        merchant: 'riya kumari',
        body: 'paid to riya kumari',
        rules: utilitiesRules,
        corrections: {'riya': 'Car'},
      );
      expect(category, 'Car');
    });

    test('known merchant matches keywords against merchant name only', () {
      final category = SmsService.categorizeWith(
        merchant: 'zomato',
        body: 'rs 500 recharge done via zomato mobile',
        rules: utilitiesRules,
      );
      expect(category, 'Food');
    });

    test('known merchant ignores body keywords it never learned', () {
      final category = SmsService.categorizeWith(
        merchant: 'riya',
        body: 'paid to riya for mobile recharge bill',
        rules: utilitiesRules,
      );
      expect(category, 'Uncategorized');
    });

    test('unknown merchant falls back to body keyword scan', () {
      final category = SmsService.categorizeWith(
        merchant: 'Unknown',
        body: 'rs 500 recharge done airtel mobile',
        rules: utilitiesRules,
      );
      expect(category, 'Utilities');
    });

    test('no matches returns Uncategorized', () {
      final category = SmsService.categorizeWith(
        merchant: 'somebody',
        body: 'paid to somebody',
        rules: utilitiesRules,
      );
      expect(category, 'Uncategorized');
    });

    test('short substring keys do not cause false positives', () {
      final category = SmsService.categorizeWith(
        merchant: 'myntra',
        body: 'paid to myntra',
        rules: utilitiesRules,
        corrections: {'my': 'Shopping'},
      );
      expect(category, 'Uncategorized');
    });
  });

  group('SmsService.mergeCorrections', () {
    test('remote wins per merchant', () {
      final merged = SmsService.mergeCorrections(
        {'riya': {'category': 'Car', 'count': 1}},
        {'riya': {'category': 'Car', 'count': 3}},
      );
      expect(merged['riya'], {'category': 'Car', 'count': 3});
    });

    test('remote entries not present locally are added', () {
      final merged = SmsService.mergeCorrections(
        {'riya': {'category': 'Car', 'count': 1}},
        {'rahul': {'category': 'Food', 'count': 2}},
      );
      expect(merged.keys, containsAll(['riya', 'rahul']));
      expect(merged['rahul'], {'category': 'Food', 'count': 2});
    });

    test('local entries not present remotely are preserved', () {
      final merged = SmsService.mergeCorrections(
        {'riya': {'category': 'Car', 'count': 1}},
        {'rahul': {'category': 'Food', 'count': 2}},
      );
      expect(merged['riya'], {'category': 'Car', 'count': 1});
    });
  });

  group('SmsService.mergeCustomRules', () {
    test('keywords are unioned per category', () {
      final merged = SmsService.mergeCustomRules(
        {'Food': ['zomato', 'swiggy']},
        {'Food': ['swiggy', 'uber eats']},
      );
      expect(merged['Food'], containsAll(['zomato', 'swiggy', 'uber eats']));
      expect(merged['Food']!.length, 3);
    });

    test('remote-only categories are added', () {
      final merged = SmsService.mergeCustomRules(
        {'Food': ['zomato']},
        {'Travel': ['uber']},
      );
      expect(merged.keys, containsAll(['Food', 'Travel']));
    });
  });
}
