import 'package:flutter_test/flutter_test.dart';
import 'package:worknest/services/leave_service.dart';

void main() {
  // ── group = a category of related tests ──────────────────────────────────
  group('LeaveService.calculateDays', () {

    // ── CASE 1: Half-day always returns 0.5, no matter the dates ─────────
    test('half day always returns 0.5', () {
      final result = LeaveService.calculateDays(
        DateTime(2025, 6, 9),   // start
        DateTime(2025, 6, 9),   // end (same day)
        true,                    // isHalfDay
      );

      expect(result, 0.5);
    });

    // ── CASE 2: Single weekday = 1.0 ─────────────────────────────────────
    test('single weekday returns 1.0', () {
      final result = LeaveService.calculateDays(
        DateTime(2025, 6, 9),   // Monday
        DateTime(2025, 6, 9),
        false,
      );

      expect(result, 1.0);
    });

    // ── CASE 3: Mon–Fri = 5 working days ─────────────────────────────────
    test('Mon to Fri returns 5 working days', () {
      final result = LeaveService.calculateDays(
        DateTime(2025, 6, 9),   // Monday
        DateTime(2025, 6, 13),  // Friday
        false,
      );

      expect(result, 5.0);
    });

    // ── CASE 4: Weekend days are skipped ─────────────────────────────────
    test('skips Saturday and Sunday', () {
      final result = LeaveService.calculateDays(
        DateTime(2025, 6, 9),   // Monday
        DateTime(2025, 6, 16),  // next Monday
        false,
      );

      // Mon + Tue + Wed + Thu + Fri + Mon = 6 (skips Sat 14 + Sun 15)
      expect(result, 6.0);
    });

    // ── CASE 5: Full week spanning 2 weekends ─────────────────────────────
    test('2-week range gives 10 working days', () {
      final result = LeaveService.calculateDays(
        DateTime(2025, 6, 9),   // Monday
        DateTime(2025, 6, 20),  // Friday next week
        false,
      );

      expect(result, 10.0);
    });

    // ── CASE 6: Start on Saturday — Saturday itself is skipped ────────────
    test('start on Saturday counts from Monday', () {
      final result = LeaveService.calculateDays(
        DateTime(2025, 6, 14),  // Saturday
        DateTime(2025, 6, 16),  // Monday
        false,
      );

      // Only Monday counts (Sat + Sun skipped)
      expect(result, 1.0);
    });

  });
}
