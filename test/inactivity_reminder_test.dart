import 'package:flutter_test/flutter_test.dart';
import 'package:money_control/Services/background_worker.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12).millisecondsSinceEpoch;
  const hourMs = 3600000;

  int hoursAgo(int h) => now - h * hourMs;

  group('shouldSendInactivityReminder', () {
    test('returns false when reminder is disabled', () {
      expect(
        shouldSendInactivityReminder(
          lastOpened: hoursAgo(24),
          lastReminded: 0,
          lastTransactionAdded: 0,
          now: now,
          reminderEnabled: false,
        ),
        isFalse,
      );
    });

    test('returns false when app was never opened', () {
      expect(
        shouldSendInactivityReminder(
          lastOpened: 0,
          lastReminded: 0,
          lastTransactionAdded: 0,
          now: now,
        ),
        isFalse,
      );
    });

    test('returns false when app was opened within the window', () {
      expect(
        shouldSendInactivityReminder(
          lastOpened: hoursAgo(5),
          lastReminded: 0,
          lastTransactionAdded: 0,
          now: now,
        ),
        isFalse,
      );
    });

    test('returns true when idle, nothing recorded, not reminded', () {
      expect(
        shouldSendInactivityReminder(
          lastOpened: hoursAgo(24),
          lastReminded: hoursAgo(10),
          lastTransactionAdded: 0,
          now: now,
        ),
        isTrue,
      );
    });

    test('returns false when a transaction was recorded within the window', () {
      expect(
        shouldSendInactivityReminder(
          lastOpened: hoursAgo(24),
          lastReminded: hoursAgo(10),
          lastTransactionAdded: hoursAgo(2),
          now: now,
        ),
        isFalse,
      );
    });

    test('returns true when a transaction was recorded outside the window', () {
      expect(
        shouldSendInactivityReminder(
          lastOpened: hoursAgo(24),
          lastReminded: hoursAgo(10),
          lastTransactionAdded: hoursAgo(7),
          now: now,
        ),
        isTrue,
      );
    });

    test('returns false when reminder was sent within the window (throttle)', () {
      expect(
        shouldSendInactivityReminder(
          lastOpened: hoursAgo(24),
          lastReminded: hoursAgo(5),
          lastTransactionAdded: 0,
          now: now,
        ),
        isFalse,
      );
    });

    test('returns false when reminder was sent exactly at the window edge', () {
      expect(
        shouldSendInactivityReminder(
          lastOpened: hoursAgo(24),
          lastReminded: hoursAgo(6),
          lastTransactionAdded: 0,
          now: now,
        ),
        isFalse,
      );
    });
  });
}
