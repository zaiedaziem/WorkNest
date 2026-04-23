import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final _supabase = Supabase.instance.client;

  // Get today's attendance record for an employee
  Future<AttendanceModel?> getTodayAttendance(String employeeId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final data = await _supabase
        .from('attendance')
        .select()
        .eq('employee_id', employeeId)
        .eq('date', today)
        .maybeSingle();

    return data != null ? AttendanceModel.fromMap(data) : null;
  }

  // Clock in
  Future<AttendanceModel> clockIn({
    required String employeeId,
    required String type, // 'office' or 'wfh'
    double? lat,
    double? lng,
    int workStartHour = 9,
    int workStartMinute = 0,
  }) async {
    final now = DateTime.now().toUtc();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Determine if late based on company work start time
    final localNow = DateTime.now();
    final isLate = localNow.hour > workStartHour ||
        (localNow.hour == workStartHour && localNow.minute >= workStartMinute);
    final status = isLate ? 'late' : 'present';

    final data = await _supabase
        .from('attendance')
        .insert({
          'employee_id': employeeId,
          'date': today,
          'clock_in': now.toIso8601String(),
          'type': type,
          'status': status,
          'clock_in_lat': lat,
          'clock_in_lng': lng,
        })
        .select()
        .single();

    return AttendanceModel.fromMap(data);
  }

  // Clock out
  Future<AttendanceModel> clockOut(String attendanceId) async {
    final now = DateTime.now().toUtc();

    final data = await _supabase
        .from('attendance')
        .update({'clock_out': now.toIso8601String()})
        .eq('id', attendanceId)
        .select()
        .single();

    return AttendanceModel.fromMap(data);
  }

  // Get attendance history
  Future<List<AttendanceModel>> getHistory(String employeeId, {int limit = 30}) async {
    final data = await _supabase
        .from('attendance')
        .select()
        .eq('employee_id', employeeId)
        .order('date', ascending: false)
        .limit(limit);

    return (data as List).map((e) => AttendanceModel.fromMap(e)).toList();
  }

  // Get attendance for a specific month
  Future<List<AttendanceModel>> getMonthHistory(
      String employeeId, int year, int month) async {
    final from = DateTime(year, month, 1).toIso8601String().substring(0, 10);
    final to = DateTime(year, month + 1, 0).toIso8601String().substring(0, 10);

    final data = await _supabase
        .from('attendance')
        .select()
        .eq('employee_id', employeeId)
        .gte('date', from)
        .lte('date', to)
        .order('date', ascending: false);

    return (data as List).map((e) => AttendanceModel.fromMap(e)).toList();
  }

  // Get approved leaves that overlap a specific month
  // Returns a list of maps: { 'start_date', 'end_date', 'policy_name',
  // 'is_half_day', 'half_day_period' }
  Future<List<Map<String, dynamic>>> getApprovedLeavesForMonth(
      String employeeId, int year, int month) async {
    final from = DateTime(year, month, 1).toIso8601String().substring(0, 10);
    final to = DateTime(year, month + 1, 0).toIso8601String().substring(0, 10);

    // Any leave where start <= monthEnd AND end >= monthStart
    final data = await _supabase
        .from('leave_requests')
        .select('start_date, end_date, is_half_day, half_day_period, '
            'leave_policies(name)')
        .eq('employee_id', employeeId)
        .eq('status', 'approved')
        .lte('start_date', to)
        .gte('end_date', from);

    return (data as List).cast<Map<String, dynamic>>();
  }
}
