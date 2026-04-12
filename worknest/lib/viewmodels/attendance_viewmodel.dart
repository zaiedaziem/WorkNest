import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceViewModel extends ChangeNotifier {
  final AttendanceService _service = AttendanceService();
  final String employeeId;

  List<AttendanceModel> _records = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  AttendanceViewModel({required this.employeeId}) {
    loadMonth();
  }

  List<AttendanceModel> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedMonth => _selectedMonth;

  // Summary counts
  int get totalPresent => _records.where((r) => r.status == 'present').length;
  int get totalLate => _records.where((r) => r.status == 'late').length;
  int get totalDays => _records.length;

  // Whether we can go forward (don't allow future months)
  bool get canGoNext =>
      _selectedMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month));

  Future<void> loadMonth() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _records = await _service.getMonthHistory(
        employeeId,
        _selectedMonth.year,
        _selectedMonth.month,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    loadMonth();
  }

  void nextMonth() {
    if (!canGoNext) return;
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    loadMonth();
  }
}
