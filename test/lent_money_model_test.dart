import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_control/Models/lent_money_model.dart';

void main() {
  group('LentMoneyModel repayments', () {
    final repayments = [
      LentRepayment(amount: 2500, date: DateTime(2026, 8, 4), note: 'First'),
      LentRepayment(amount: 2500, date: DateTime(2026, 8, 5)),
    ];

    test('repaidAmount sums all repayments', () {
      final model = LentMoneyModel(
        id: '1',
        friendName: 'Rahul',
        amount: 5000,
        dateLent: DateTime(2026, 8, 3),
        repayments: repayments,
      );
      expect(model.repaidAmount, 5000.0);
    });

    test('remainingAmount is amount minus repaid', () {
      final model = LentMoneyModel(
        id: '1',
        friendName: 'Rahul',
        amount: 5000,
        dateLent: DateTime(2026, 8, 3),
        repayments: repayments,
      );
      expect(model.remainingAmount, 0.0);
    });

    test('remainingAmount reflects partial repayment', () {
      final model = LentMoneyModel(
        id: '1',
        friendName: 'Rahul',
        amount: 5000,
        dateLent: DateTime(2026, 8, 3),
        repayments: [repayments.first],
      );
      expect(model.remainingAmount, 2500.0);
    });

    test('remainingAmount clamps at zero when overpaid', () {
      final model = LentMoneyModel(
        id: '1',
        friendName: 'Rahul',
        amount: 5000,
        dateLent: DateTime(2026, 8, 3),
        repayments: [
          LentRepayment(amount: 6000, date: DateTime(2026, 8, 4)),
        ],
      );
      expect(model.remainingAmount, 0.0);
    });

    test('fromMap/toMap round-trip preserves repayments', () {
      final model = LentMoneyModel(
        id: '1',
        friendName: 'Rahul',
        amount: 5000,
        note: 'Trip advance',
        dateLent: DateTime(2026, 8, 3),
        createdAt: DateTime(2026, 8, 3, 10, 30),
        repayments: repayments,
      );
      final restored = LentMoneyModel.fromMap(model.id, model.toMap());
      expect(restored.friendName, 'Rahul');
      expect(restored.amount, 5000.0);
      expect(restored.repayments.length, 2);
      expect(restored.repaidAmount, 5000.0);
      expect(restored.repayments.first.amount, 2500.0);
      expect(restored.repayments.first.note, 'First');
      expect(restored.repayments.first.date, DateTime(2026, 8, 4));
    });

    test('legacy doc without repayments defaults to empty list', () {
      final model = LentMoneyModel.fromMap('1', {
        'friendName': 'Rahul',
        'amount': 5000,
        'note': '',
        'dateLent': DateTime(2026, 8, 3),
        'isSettled': false,
        'type': 'lent',
        'createdAt': Timestamp.fromDate(DateTime(2026, 8, 3, 10, 30)),
      });
      expect(model.repayments, isEmpty);
      expect(model.repaidAmount, 0.0);
      expect(model.remainingAmount, 5000.0);
    });

    test('toMap contains serialized repayments', () {
      final model = LentMoneyModel(
        id: '1',
        friendName: 'Rahul',
        amount: 5000,
        dateLent: DateTime(2026, 8, 3),
        createdAt: DateTime(2026, 8, 3, 10, 30),
        repayments: repayments,
      );
      final map = model.toMap();
      expect(map['repayments'], isA<List>());
      expect((map['repayments'] as List).length, 2);
      expect((map['repayments'] as List).first['amount'], 2500.0);
      expect((map['repayments'] as List).first['note'], 'First');
    });
  });
}
