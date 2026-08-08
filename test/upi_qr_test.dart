import 'package:flutter_test/flutter_test.dart';
import 'package:money_control/Utils/upi_qr.dart';

void main() {
  group('parseUpiQr() — standard upi://pay URL', () {
    test('parses vpa, name, amount, note, refs', () {
      final result = parseUpiQr(
        'upi://pay?pa=rohit@oksbi&pn=Rohit%20Sharma&am=500.50&tn=Groceries'
        '&cu=INR&tr=TXN123&tid=REF456',
      );
      expect(result, isNotNull);
      expect(result!.vpa, 'rohit@oksbi');
      expect(result.name, 'Rohit Sharma');
      expect(result.amount, 500.50);
      expect(result.note, 'Groceries');
      expect(result.txnRef, 'TXN123');
      expect(result.txnId, 'REF456');
    });

    test('parses legacy payeeVpa parameter', () {
      final result = parseUpiQr('upi://pay?payeeVpa=person@ybl&pn=Person');
      expect(result, isNotNull);
      expect(result!.vpa, 'person@ybl');
      expect(result.name, 'Person');
      expect(result.amount, isNull);
    });

    test('handles uppercase scheme and parameter keys', () {
      final result = parseUpiQr('UPI://PAY?PA=abc@ybl&AM=200&PN=ABC');
      expect(result, isNotNull);
      expect(result!.vpa, 'abc@ybl');
      expect(result.amount, 200.0);
      expect(result.name, 'ABC');
    });

    test('parses amount with thousands separator', () {
      final result = parseUpiQr('upi://pay?pa=a@b&am=1,000.50');
      expect(result, isNotNull);
      expect(result!.amount, 1000.50);
    });

    test('ignores unparseable amount but keeps vpa', () {
      final result = parseUpiQr('upi://pay?pa=a@b&am=abc');
      expect(result, isNotNull);
      expect(result!.vpa, 'a@b');
      expect(result.amount, isNull);
    });

    test('returns null when pa is missing', () {
      expect(parseUpiQr('upi://pay?pn=Name&am=10'), isNull);
    });
  });

  group('parseUpiQr() — bare VPA strings', () {
    test('parses a plain VPA', () {
      final result = parseUpiQr('rohit@upi');
      expect(result, isNotNull);
      expect(result!.vpa, 'rohit@upi');
      expect(result.name, isNull);
    });

    test('parses numeric VPA handles', () {
      final result = parseUpiQr('9876543210@ybl');
      expect(result, isNotNull);
      expect(result!.vpa, '9876543210@ybl');
    });
  });

  group('parseUpiQr() — invalid payloads', () {
    test('rejects empty and whitespace', () {
      expect(parseUpiQr(''), isNull);
      expect(parseUpiQr('   '), isNull);
    });

    test('rejects http links', () {
      expect(
        parseUpiQr('https://example.com/pay?pa=rohit@upi'),
        isNull,
      );
    });

    test('rejects random text without an @ handle', () {
      expect(parseUpiQr('hello world this is not a qr code'), isNull);
    });

    test('rejects text with @ but no valid handle', () {
      expect(parseUpiQr('user@'), isNull);
      expect(parseUpiQr('@upi'), isNull);
    });
  });

  group('UpiQrData.manual sentinel', () {
    test('has an empty vpa and flags isManual', () {
      expect(UpiQrData.manual.vpa, isEmpty);
      expect(UpiQrData.manual.isManual, isTrue);
      expect(const UpiQrData(vpa: 'x@upi').isManual, isFalse);
    });
  });
}
