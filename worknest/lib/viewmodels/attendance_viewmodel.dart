import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../services/error_message.dart';

/// Status of a single working day in the month view.
enum DayStatus { present, late, onLeave, absent, upcoming, weekend, holiday }

/// Filter options shown as chips above the list.
enum DayFilter { all, present, late, onLeave, absent }

/// One row in the attendance list — represents a single working day
/// (Mon–Fri) and combines attendance + leave data.
class DayRecord {
  final DateTime date;
  final DayStatus status;
  final AttendanceModel? attendance;  // non-null for present / late
  final String? leaveTypeName;        // non-null for onLeave
  final bool isHalfDay;               // only relevant for onLeave
  final String? halfDayPeriod;        // 'morning' / 'afternoon'
  final String? holidayName;          // non-null for holiday

  DayRecord({
    required this.date,
    required this.status,
    this.attendance,
    this.leaveTypeName,
    this.isHalfDay = false,
    this.halfDayPeriod,
    this.holidayName,
  });
}

class AttendanceViewModel extends ChangeNotifier {
  final AttendanceService _service = AttendanceService();
  final String employeeId;

  List<AttendanceModel> _records = [];
  List<DayRecord> _dayRecords = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DayFilter _filter = DayFilter.all;

  AttendanceViewModel({required this.employeeId}) {
    loadMonth();
  }

  List<AttendanceModel> get records => _records;
  List<DayRecord> get dayRecords => _dayRecords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedMonth => _selectedMonth;
  DayFilter get filter => _filter;

  /// Day records filtered by the active chip.
  /// Weekends are always shown in 'all' view; hidden when a filter is active.
  List<DayRecord> get filteredDayRecords {
    switch (_filter) {
      case DayFilter.all:
        return _dayRecords;
      case DayFilter.present:
        return _dayRecords
            .where((d) => d.status == DayStatus.present)
            .toList();
      case DayFilter.late:
        return _dayRecords
            .where((d) => d.status == DayStatus.late)
            .toList();
      case DayFilter.onLeave:
        return _dayRecords
            .where((d) => d.status == DayStatus.onLeave)
            .toList();
      case DayFilter.absent:
        return _dayRecords
            .where((d) => d.status == DayStatus.absent)
            .toList();
    }
  }

  void setFilter(DayFilter f) {
    if (_filter == f) return;
    _filter = f;
    notifyListeners();
  }

  // Summary counts — based on day records (not raw attendance)
  int get totalPresent =>
      _dayRecords.where((d) => d.status == DayStatus.present).length;
  int get totalLate =>
      _dayRecords.where((d) => d.status == DayStatus.late).length;
  int get totalOnLeave =>
      _dayRecords.where((d) => d.status == DayStatus.onLeave).length;
  int get totalAbsent =>
      _dayRecords.where((d) => d.status == DayStatus.absent).length;
  int get totalWorkingDays =>
      _dayRecords.where((d) => d.status != DayStatus.upcoming).length;

  /// Sum of clock-in to clock-out durations across the month.
  Duration get totalHoursWorked {
    Duration total = Duration.zero;
    for (final r in _records) {
      final d = r.duration;
      if (d != null) total += d;
    }
    return total;
  }

  /// Formatted like "142h 30m" (or "45m" if under an hour).
  String get totalHoursWorkedText {
    final total = totalHoursWorked;
    if (total == Duration.zero) return '0h';
    final h = total.inHours;
    final m = total.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  /// On-time rate: present / (present + late). Returns null if no attendance
  /// yet this month (so the UI can show a placeholder).
  double? get onTimeRate {
    final attendanceTotal = totalPresent + totalLate;
    if (attendanceTotal == 0) return null;
    return totalPresent / attendanceTotal;
  }

  /// Formatted like "90%" or "—" if no attendance yet.
  String get onTimeRateText {
    final rate = onTimeRate;
    if (rate == null) return '—';
    return '${(rate * 100).round()}%';
  }

  // Whether we can go forward (don't allow future months)
  bool get canGoNext =>
      _selectedMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month));

  Future<void> loadMonth() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Parallel fetch: attendance + approved leaves + public holidays
      final results = await Future.wait([
        _service.getMonthHistory(
          employeeId,
          _selectedMonth.year,
          _selectedMonth.month,
        ),
        _service.getApprovedLeavesForMonth(
          employeeId,
          _selectedMonth.year,
          _selectedMonth.month,
        ),
        _service.getPublicHolidaysForMonth(
          _selectedMonth.year,
          _selectedMonth.month,
        ),
      ]);

      _records = results[0] as List<AttendanceModel>;
      final leaves = results[1] as List<Map<String, dynamic>>;
      final holidays = results[2] as Map<String, String>;

      _dayRecords = buildDayRecords(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
        today: DateTime.now(),
        attendance: _records,
        leaves: leaves,
        holidays: holidays,
      );
    } catch (e) {
      _errorMessage = friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate one DayRecord per calendar day in the given month.
  /// Weekends are included with DayStatus.weekend.
  /// Days are ordered Day 1 → end of month (chronological).
  /// Pure function (no network), so it is unit-tested.
  static List<DayRecord> buildDayRecords({
    required int year,
    required int month,
    required DateTime today,
    required List<AttendanceModel> attendance,
    required List<Map<String, dynamic>> leaves,
    required Map<String, String> holidays,
  }) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final todayOnly = DateTime(today.year, today.month, today.day);

    // Index attendance by date (yyyy-mm-dd key)
    final attByDate = <String, AttendanceModel>{};
    for (final a in attendance) {
      final key = _dateKey(a.date);
      attByDate[key] = a;
    }

    final result = <DayRecord>[];
    for (int d = 1; d <= lastDay; d++) {
      final day = DateTime(year, month, d);

      // Weekend → show as weekend card, no attendance logic
      if (day.weekday == DateTime.saturday ||
          day.weekday == DateTime.sunday) {
        result.add(DayRecord(date: day, status: DayStatus.weekend));
        continue;
      }

      final key = _dateKey(day);
      final att = attByDate[key];

      // 0. Public holiday (unless they clocked in that day) — not a working day
      final holidayName = holidays[key];
      if (holidayName != null && att == null) {
        result.add(DayRecord(
          date: day,
          status: DayStatus.holiday,
          holidayName: holidayName,
        ));
        continue;
      }

      // 1. Approved leave wins
      final leave = _findLeaveCovering(day, leaves);
      if (leave != null) {
        result.add(DayRecord(
          date: day,
          status: DayStatus.onLeave,
          leaveTypeName:
              (leave['leave_policies']?['name'] as String?) ?? 'Leave',
          isHalfDay: leave['is_half_day'] == true,
          halfDayPeriod: leave['half_day_period'] as String?,
        ));
        continue;
      }

      // 2. Attendance record
      if (att != null) {
        result.add(DayRecord(
          date: day,
          status: att.status == 'late' ? DayStatus.late : DayStatus.present,
          attendance: att,
        ));
        continue;
      }

      // 3. Future day in current month → upcoming
      if (day.isAfter(todayOnly)) {
        result.add(DayRecord(date: day, status: DayStatus.upcoming));
        continue;
      }

      // 4. Past working day with no attendance and no leave → absent
      result.add(DayRecord(date: day, status: DayStatus.absent));
    }

    // Day 1 → end of month (chronological)
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  static Map<String, dynamic>? _findLeaveCovering(
    DateTime day,
    List<Map<String, dynamic>> leaves,
  ) {
    for (final l in leaves) {
      final start = DateTime.parse(l['start_date'] as String);
      final end = DateTime.parse(l['end_date'] as String);
      final startOnly = DateTime(start.year, start.month, start.day);
      final endOnly = DateTime(end.year, end.month, end.day);
      if (!day.isBefore(startOnly) && !day.isAfter(endOnly)) {
        return l;
      }
    }
    return null;
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    _filter = DayFilter.all;
    loadMonth();
  }

  void nextMonth() {
    if (!canGoNext) return;
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    _filter = DayFilter.all;
    loadMonth();
  }
}
