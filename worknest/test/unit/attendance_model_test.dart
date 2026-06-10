import 'package:flutter_test/flutter_test.dart';
import 'package:worknest/models/attendance_model.dart';

// Helper — build AttendanceModel with optional clock-in/out
AttendanceModel makeAttendance({
  DateTime? clockIn,
  DateTime? clockOut,
  String status = 'present',
  String type = 'office',
}) {
  return AttendanceModel(
    id: 'test-id',
    employeeId: 'emp-1',
    date: DateTime(2025, 6, 9),
    clockIn: clockIn,
    clockOut: clockOut,
    type: type,
    status: status,
  );
}

void main() {

  // ─────────────────────────────────────────────────────────────────────────
  // 1. isClockedIn / isClockedOut
  // ─────────────────────────────────────────────────────────────────────────
  group('AttendanceModel.isClockedIn and isClockedOut', () {

    test('no clockIn → isClockedIn is false', () {
      final a = makeAttendance(clockIn: null);
      expect(a.isClockedIn, false);
    });

    test('has clockIn → isClockedIn is true', () {
      final a = makeAttendance(clockIn: DateTime(2025, 6, 9, 9, 0));
      expect(a.isClockedIn, true);
    });

    test('no clockOut → isClockedOut is false', () {
      final a = makeAttendance(clockOut: null);
      expect(a.isClockedOut, false);
    });

    test('has clockOut → isClockedOut is true', () {
      final a = makeAttendance(
        clockIn: DateTime(2025, 6, 9, 9, 0),
        clockOut: DateTime(2025, 6, 9, 18, 0),
      );
      expect(a.isClockedOut, true);
    });

  });


  // ─────────────────────────────────────────────────────────────────────────
  // 2. duration — returns null if either time is missing
  // ─────────────────────────────────────────────────────────────────────────
  group('AttendanceModel.duration', () {

    test('no clockIn → duration is null', () {
      final a = makeAttendance(clockIn: null, clockOut: DateTime(2025, 6, 9, 18, 0));
      expect(a.duration, isNull);
    });

    test('no clockOut → duration is null', () {
      final a = makeAttendance(clockIn: DateTime(2025, 6, 9, 9, 0), clockOut: null);
      expect(a.duration, isNull);
    });

    test('9:00 → 17:00 = 8 hours', () {
      final a = makeAttendance(
        clockIn:  DateTime(2025, 6, 9, 9, 0),
        clockOut: DateTime(2025, 6, 9, 17, 0),
      );
      expect(a.duration, const Duration(hours: 8));
    });

    test('9:00 → 18:30 = 9h 30m', () {
      final a = makeAttendance(
        clockIn:  DateTime(2025, 6, 9, 9, 0),
        clockOut: DateTime(2025, 6, 9, 18, 30),
      );
      expect(a.duration, const Duration(hours: 9, minutes: 30));
    });

    test('30-minute shift = 30 minutes', () {
      final a = makeAttendance(
        clockIn:  DateTime(2025, 6, 9, 9, 0),
        clockOut: DateTime(2025, 6, 9, 9, 30),
      );
      expect(a.duration, const Duration(minutes: 30));
    });

  });


  // ─────────────────────────────────────────────────────────────────────────
  // 3. durationText — human-readable "Xh Ym" string
  // ─────────────────────────────────────────────────────────────────────────
  group('AttendanceModel.durationText', () {

    test('no duration → "-"', () {
      final a = makeAttendance(clockIn: null, clockOut: null);
      expect(a.durationText, '-');
    });

    test('8h 0m → "8h 0m"', () {
      final a = makeAttendance(
        clockIn:  DateTime(2025, 6, 9, 9, 0),
        clockOut: DateTime(2025, 6, 9, 17, 0),
      );
      expect(a.durationText, '8h 0m');
    });

    test('9h 30m → "9h 30m"', () {
      final a = makeAttendance(
        clockIn:  DateTime(2025, 6, 9, 9, 0),
        clockOut: DateTime(2025, 6, 9, 18, 30),
      );
      expect(a.durationText, '9h 30m');
    });

    test('0h 45m → "0h 45m"', () {
      final a = makeAttendance(
        clockIn:  DateTime(2025, 6, 9, 9, 0),
        clockOut: DateTime(2025, 6, 9, 9, 45),
      );
      expect(a.durationText, '0h 45m');
    });

    test('exactly 1 hour → "1h 0m"', () {
      final a = makeAttendance(
        clockIn:  DateTime(2025, 6, 9, 9, 0),
        clockOut: DateTime(2025, 6, 9, 10, 0),
      );
      expect(a.durationText, '1h 0m');
    });

  });

}
