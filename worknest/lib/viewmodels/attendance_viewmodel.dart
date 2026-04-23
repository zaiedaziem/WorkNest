import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

/// Status of a single working day in the month view.
enum DayStatus { present, late, onLeave, absent, upcoming }

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

  DayRecord({
    required this.date,
    required this.status,
    this.attendance,
    this.leaveTypeName,
    this.isHalfDay = false,
    this.halfDayPeriod,
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
      // Parallel fetch: attendance + approved leaves
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
      ]);

      _records = results[0] as List<AttendanceModel>;
      final leaves = results[1] as List<Map<String, dynamic>>;

      _dayRecords = _buildDayRecords(_records, leaves);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate one DayRecord per working day (Mon–Fri) in the selected month.
  /// Most-recent day first (matches existing UX).
  List<DayRecord> _buildDayRecords(
    List<AttendanceModel> attendance,
    List<Map<String, dynamic>> leaves,
  ) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final lastDay = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();
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

      // Skip weekends
      if (day.weekday == DateTime.saturday ||
          day.weekday == DateTime.sunday) {
        continue;
      }

      final key = _dateKey(day);
      final att = attByDate[key];

      // 1. Attendance record wins
      if (att != null) {
        result.add(DayRecord(
          date: day,
          status: att.status == 'late' ? DayStatus.late : DayStatus.present,
          attendance: att,
        ));
        continue;
      }

      // 2. Approved leave covers this day?
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

      // 3. Future day in current month → upcoming
      if (day.isAfter(todayOnly)) {
        result.add(DayRecord(date: day, status: DayStatus.upcoming));
        continue;
      }

      // 4. Past working day with no attendance and no leave → absent
      result.add(DayRecord(date: day, status: DayStatus.absent));
    }

    // Most recent first
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  Map<String, dynamic>? _findLeaveCovering(
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

  String _dateKey(DateTime d) =>
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
