import 'package:flutter_test/flutter_test.dart';
import 'package:worknest/models/ot_request_model.dart';

// Helper — build an OtRequestModel with custom times
OtRequestModel makeOtRequest({
  String startTime = '18:00:00',
  String endTime   = '20:00:00',
  String date      = '2025-06-09',
  String otType    = 'weekday',
}) {
  return OtRequestModel(
    id: 'test-id',
    companyId: 'co-1',
    employeeId: 'emp-1',
    date: date,
    startTime: startTime,
    endTime: endTime,
    reason: 'Test reason',
    otType: otType,
    status: 'pending',
    createdAt: DateTime(2025, 6, 9),
  );
}

void main() {

  // ─────────────────────────────────────────────────────────────────────────
  // 1. otHours — calculates hours between startTime and endTime
  // ─────────────────────────────────────────────────────────────────────────
  group('OtRequestModel.otHours', () {

    test('18:00 → 20:00 = 2.0 hours', () {
      expect(makeOtRequest(startTime: '18:00:00', endTime: '20:00:00').otHours, 2.0);
    });

    test('09:00 → 17:00 = 8.0 hours', () {
      expect(makeOtRequest(startTime: '09:00:00', endTime: '17:00:00').otHours, 8.0);
    });

    test('18:00 → 18:30 = 0.5 hours', () {
      expect(makeOtRequest(startTime: '18:00:00', endTime: '18:30:00').otHours, 0.5);
    });

    test('18:00 → 19:15 = 1.25 hours', () {
      expect(makeOtRequest(startTime: '18:00:00', endTime: '19:15:00').otHours, 1.25);
    });

    test('same start and end = 0.0 hours', () {
      expect(makeOtRequest(startTime: '18:00:00', endTime: '18:00:00').otHours, 0.0);
    });

    test('end before start → negative (caller must validate)', () {
      // The model just does math — validation is in the UI layer
      expect(makeOtRequest(startTime: '20:00:00', endTime: '18:00:00').otHours, -2.0);
    });

    test('malformed time string → returns 0 without crashing', () {
      expect(makeOtRequest(startTime: 'bad', endTime: 'data').otHours, 0.0);
    });

  });


  // ─────────────────────────────────────────────────────────────────────────
  // 2. displayDate — converts "yyyy-MM-dd" → "d Mon yyyy"
  // ─────────────────────────────────────────────────────────────────────────
  group('OtRequestModel.displayDate', () {

    test('"2025-06-09" → "9 Jun 2025"', () {
      expect(makeOtRequest(date: '2025-06-09').displayDate, '9 Jun 2025');
    });

    test('"2025-01-01" → "1 Jan 2025"', () {
      expect(makeOtRequest(date: '2025-01-01').displayDate, '1 Jan 2025');
    });

    test('"2025-12-25" → "25 Dec 2025"', () {
      expect(makeOtRequest(date: '2025-12-25').displayDate, '25 Dec 2025');
    });

    test('malformed date string → falls back to raw string', () {
      // Should not throw — falls back gracefully
      final result = makeOtRequest(date: 'not-a-date').displayDate;
      expect(result, 'not-a-date');
    });

  });


  // ─────────────────────────────────────────────────────────────────────────
  // 3. displayStartTime / displayEndTime — trims seconds from "HH:mm:ss"
  // ─────────────────────────────────────────────────────────────────────────
  group('OtRequestModel.displayStartTime and displayEndTime', () {

    test('"18:00:00" → "18:00"', () {
      expect(makeOtRequest(startTime: '18:00:00').displayStartTime, '18:00');
    });

    test('"09:30:45" → "09:30"', () {
      expect(makeOtRequest(startTime: '09:30:45').displayStartTime, '09:30');
    });

    test('"20:00:00" end → "20:00"', () {
      expect(makeOtRequest(endTime: '20:00:00').displayEndTime, '20:00');
    });

    test('short string (no seconds) returns as-is', () {
      // "18:00" is already 5 chars — no substring needed
      expect(makeOtRequest(startTime: '18:00').displayStartTime, '18:00');
    });

  });

}
