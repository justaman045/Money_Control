import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_control/Utils/upi_apps.dart';

const _fallback = Color(0xFF6C63FF);

const _pinned = [
  UpiAppDescriptor(
    name: 'GPay',
    package: 'com.google.android.apps.nbu.paisa.user',
    icon: 'G',
    color: Color(0xFF4285F4),
  ),
  UpiAppDescriptor(
    name: 'PhonePe',
    package: 'com.phonepe.app',
    icon: 'P',
    color: Color(0xFF5F259F),
  ),
  UpiAppDescriptor(
    name: 'Paytm',
    package: 'net.one97.paytm',
    icon: 'P',
    color: Color(0xFF002970),
  ),
  UpiAppDescriptor(
    name: 'BHIM',
    package: 'in.org.npci.upiapp',
    icon: 'B',
    color: Color(0xFF0033A0),
  ),
  UpiAppDescriptor(
    name: 'CRED',
    package: 'com.dreamplug.androidapp',
    icon: 'C',
    color: Color(0xFF1A1A2E),
  ),
  UpiAppDescriptor(name: 'Any UPI', package: null, icon: 'U', color: _fallback),
];

void main() {
  group('filterInstalledUpiApps()', () {
    test('keeps only installed pinned apps in pinned order', () {
      final result = filterInstalledUpiApps(
        pinned: _pinned,
        installedPackages: {
          'com.phonepe.app': 'PhonePe',
          'com.google.android.apps.nbu.paisa.user': 'GPay',
        },
        fallbackColor: _fallback,
      );
      expect(result.map((a) => a.name), ['GPay', 'PhonePe']);
      expect(result.map((a) => a.icon), ['G', 'P']);
    });

    test('appends unlisted installed UPI apps with their real label', () {
      final result = filterInstalledUpiApps(
        pinned: _pinned,
        installedPackages: {
          'com.phonepe.app': 'PhonePe',
          'in.sbi.yonoapp': 'YONO SBI',
          'com.amazon.aa': 'Amazon Pay',
        },
        fallbackColor: _fallback,
      );
      expect(result.map((a) => a.name), ['PhonePe', 'YONO SBI', 'Amazon Pay']);
      expect(result.map((a) => a.package), [
        'com.phonepe.app',
        'in.sbi.yonoapp',
        'com.amazon.aa',
      ]);
      expect(result.last.icon, 'A');
      expect(result.last.color, _fallback);
    });

    test('hides system chooser when any UPI app is installed', () {
      final result = filterInstalledUpiApps(
        pinned: _pinned,
        installedPackages: {'net.one97.paytm': 'Paytm'},
        fallbackColor: _fallback,
      );
      expect(result.map((a) => a.name), ['Paytm']);
      expect(result.any((a) => a.isSystemChooser), isFalse);
    });

    test('falls back to system chooser when nothing is installed', () {
      final result = filterInstalledUpiApps(
        pinned: _pinned,
        installedPackages: {},
        fallbackColor: _fallback,
      );
      expect(result.length, 1);
      expect(result.first.name, 'Any UPI');
      expect(result.first.isSystemChooser, isTrue);
    });

    test('uses package name as label when the label is empty', () {
      final result = filterInstalledUpiApps(
        pinned: _pinned,
        installedPackages: {'com.some.app': '   '},
        fallbackColor: _fallback,
      );
      expect(result.single.name, 'com.some.app');
      expect(result.single.icon, 'C');
    });
  });
}
