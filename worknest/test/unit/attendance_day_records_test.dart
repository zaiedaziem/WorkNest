import 'package:flutter_test/flutter_test.dart';
import 'package:worknest/models/attendance_model.dart';
import 'package:worknest/viewmodels/attendance_viewmodel.dart';

void main() {
  // September 2026: the 16th (Wednesday) is Malaysia Day; 19th–20th is a weekend.
  // "Today" is pinned to Tuesday 22 September so the test never depends on the real date.
  final today = DateTime(2026, 9, 22, 10);

  AttendanceModel att(int day, {String status = 'present'}) => AttendanceModel.fromMap({
        'id': 'a$day',
        'employee_id': 'e1',
        'date': '2026-09-${day.toString().padLeft(2, '0')}',
        'clock_in': '2026-09-${day.toString().padLeft(2, '0')}T01:00:00Z',
        'type': 'office',
        'status': status,
      });

  List<DayRecord> build({
    List<AttendanceModel> attendance = const [],
    List<Map<String, dynamic>> leaves = const [],
    Map<String, String> holidays = const {},
  }) =>
      AttendanceViewModel.buildDayRecords(
        year: 2026,
        month: 9,
        today: today,
        attendance: attendance,
        leaves: leaves,
        holidays: holidays,
      );

  DayRecord on(List<DayRecord> days, int day) =>
      days.firstWhere((d) => d.date.day == day);

  group('AttendanceViewModel.buildDayRecords', () {
    test('creates one record per calendar day, in order', () {
      final days = build();

      expect(days.length, 30);
      expect(days.first.date, DateTime(2026, 9, 1));
      expect(days.last.date, DateTime(2026, 9, 30));
    });

    test('weekends are weekend, not absent', () {
      final days = build();

      expect(on(days, 19).status, DayStatus.weekend);
      expect(on(days, 20).status, DayStatus.weekend);
    });

    test('a public holiday is a holiday with its name, not absent', () {
      final days = build(holidays: {'2026-09-16': 'Malaysia Day'});

      expect(on(days, 16).status, DayStatus.holiday);
      expect(on(days, 16).holidayName, 'Malaysia Day');
    });

    test('without the holiday list the same day would count as absent', () {
      final days = build();

      expect(on(days, 16).status, DayStatus.absent);
    });

    test('clocking in on a holiday still shows the day as worked', () {
      final days = build(
        attendance: [att(16)],
        holidays: {'2026-09-16': 'Malaysia Day'},
      );

      expect(on(days, 16).status, DayStatus.present);
    });

    test('late and present come from the attendance status', () {
      final days = build(attendance: [att(14), att(15, status: 'late')]);

      expect(on(days, 14).status, DayStatus.present);
      expect(on(days, 15).status, DayStatus.late);
    });

    test('approved leave covers every day in its range', () {
      final days = build(leaves: [
        {
          'start_date': '2026-09-17',
          'end_date': '2026-09-18',
          'is_half_day': false,
          'leave_policies': {'name': 'Annual Leave'},
        }
      ]);

      expect(on(days, 17).status, DayStatus.onLeave);
      expect(on(days, 18).status, DayStatus.onLeave);
      expect(on(days, 17).leaveTypeName, 'Annual Leave');
    });

    test('past working days with no record are absent; future ones are upcoming', () {
      final days = build();

      expect(on(days, 21).status, DayStatus.absent);    // yesterday
      expect(on(days, 22).status, DayStatus.absent);    // today, not clocked in
      expect(on(days, 23).status, DayStatus.upcoming);  // tomorrow
    });

    test('holidays are not counted as absent in the month total', () {
      final days = build(holidays: {'2026-09-16': 'Malaysia Day'});
      final absent = days.where((d) => d.status == DayStatus.absent).length;

      // 16 past/today weekdays (1–22 Sep) minus the holiday
      expect(absent, 15);
    });
  });
}
