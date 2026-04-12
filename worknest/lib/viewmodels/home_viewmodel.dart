import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

enum HomeState { idle, loading, success, error }

class HomeViewModel extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();

  final UserModel user;
  final CompanyModel company;

  HomeViewModel({required this.user, required this.company}) {
    loadTodayAttendance();
  }

  HomeState _state = HomeState.idle;
  String? _errorMessage;
  String? _successMessage;
  AttendanceModel? _todayAttendance;
  List<AttendanceModel> _recentAttendance = [];
  int _monthPresent = 0;
  int _monthLate = 0;
  int _monthTotal = 0;

  HomeState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  AttendanceModel? get todayAttendance => _todayAttendance;
  List<AttendanceModel> get recentAttendance => _recentAttendance;
  int get monthPresent => _monthPresent;
  int get monthLate => _monthLate;
  int get monthTotal => _monthTotal;
  bool get isLoading => _state == HomeState.loading;
  bool get isClockedIn => _todayAttendance?.isClockedIn ?? false;
  bool get isClockedOut => _todayAttendance?.isClockedOut ?? false;

  Future<void> loadTodayAttendance() async {
    _state = HomeState.loading;
    notifyListeners();

    try {
      final now = DateTime.now();
      // Load today + month stats + recent in parallel
      final results = await Future.wait([
        _attendanceService.getTodayAttendance(user.id),
        _attendanceService.getMonthHistory(user.id, now.year, now.month),
      ]);

      _todayAttendance = results[0] as AttendanceModel?;
      final monthRecords = results[1] as List<AttendanceModel>;

      _monthTotal = monthRecords.length;
      _monthPresent = monthRecords.where((r) => r.status == 'present').length;
      _monthLate = monthRecords.where((r) => r.status == 'late').length;

      // Recent = last 3 excluding today
      _recentAttendance = monthRecords
          .where((r) =>
              r.date.toIso8601String().substring(0, 10) !=
              now.toIso8601String().substring(0, 10))
          .take(3)
          .toList();

      _state = HomeState.idle;
    } catch (e) {
      _state = HomeState.idle;
    }

    notifyListeners();
  }

  Future<void> clockIn(String type) async {
    _state = HomeState.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      double? lat, lng;

      if (type == 'office' && company.locationEnabled) {
        // Check location permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          throw Exception('Location permission is required for In Office clock in.');
        }

        // Get current position
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        lat = position.latitude;
        lng = position.longitude;

        // Check if within office radius
        if (company.hasLocation) {
          final distance = Geolocator.distanceBetween(
            lat, lng,
            company.officeLat!, company.officeLng!,
          );

          if (distance > company.officeRadius) {
            throw Exception(
                'You are ${distance.toStringAsFixed(0)}m away from the office. Must be within ${company.officeRadius}m.');
          }
        }
      }

      _todayAttendance = await _attendanceService.clockIn(
        employeeId: user.id,
        type: type,
        lat: lat,
        lng: lng,
        workStartHour: company.workStartHour,
        workStartMinute: company.workStartMinute,
      );

      _successMessage = type == 'office'
          ? 'Clocked in successfully — In Office'
          : 'Clocked in successfully — WFH';
      _state = HomeState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = HomeState.error;
    }

    notifyListeners();
  }

  Future<void> clockOut() async {
    if (_todayAttendance == null) return;

    _state = HomeState.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _todayAttendance = await _attendanceService.clockOut(_todayAttendance!.id);
      _successMessage = 'Clocked out successfully. Duration: ${_todayAttendance!.durationText}';
      _state = HomeState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = HomeState.error;
    }

    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
