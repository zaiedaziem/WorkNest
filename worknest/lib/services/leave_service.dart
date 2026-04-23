import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leave_policy_model.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_request_model.dart';

class LeaveService {
  final _supabase = Supabase.instance.client;

  // ── Get all active leave policies for a company (UI handles gender visibility) ──
  Future<List<LeavePolicyModel>> getPolicies(String companyId, {String gender = 'other'}) async {
    final data = await _supabase
        .from('leave_policies')
        .select()
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('name');

    return (data as List).map((e) => LeavePolicyModel.fromMap(e)).toList();
  }

  // ── Get leave balances for an employee (current year) ─────────────────────
  Future<List<LeaveBalanceModel>> getBalances(String employeeId) async {
    final year = DateTime.now().year;
    final data = await _supabase
        .from('leave_balances')
        .select('*, leave_policies(name, code)')
        .eq('employee_id', employeeId)
        .eq('year', year);

    return (data as List).map((e) => LeaveBalanceModel.fromMap(e)).toList();
  }

  // ── Get leave request history for an employee ─────────────────────────────
  Future<List<LeaveRequestModel>> getHistory(String employeeId) async {
    final data = await _supabase
        .from('leave_requests')
        .select('*, leave_policies(name, code)')
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => LeaveRequestModel.fromMap(e)).toList();
  }

  // ── Submit a new leave request ────────────────────────────────────────────
  Future<void> submitRequest({
    required String employeeId,
    required String companyId,
    required String leavePolicyId,
    required DateTime startDate,
    required DateTime endDate,
    required bool isHalfDay,
    String? halfDayPeriod,
    required double totalDays,
    String? reason,
    String? attachmentUrl,
  }) async {
    final year = DateTime.now().year;

    debugPrint('[LeaveService] Step 1 — checking balance...');

    // Check leave balance
    final balanceData = await _supabase
        .from('leave_balances')
        .select()
        .eq('employee_id', employeeId)
        .eq('leave_policy_id', leavePolicyId)
        .eq('year', year)
        .maybeSingle()
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () =>
              throw Exception('Timed out checking balance. Check your connection.'),
        );

    debugPrint('[LeaveService] Step 1 done — balanceData: $balanceData');

    if (balanceData != null) {
      final balance = LeaveBalanceModel.fromMap(balanceData);
      if (totalDays > balance.remainingDays) {
        throw Exception(
            'Insufficient balance. You have ${balance.remainingDays} day(s) remaining.');
      }
    }

    debugPrint('[LeaveService] Step 2 — inserting leave_request...');

    // Insert leave request
    await _supabase.from('leave_requests').insert({
      'employee_id': employeeId,
      'company_id': companyId,
      'leave_policy_id': leavePolicyId,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
      'is_half_day': isHalfDay,
      'half_day_period': halfDayPeriod,
      'total_days': totalDays,
      'reason': reason,
      'attachment_url': attachmentUrl,
      'status': 'pending',
    }).timeout(
      const Duration(seconds: 15),
      onTimeout: () =>
          throw Exception('Timed out inserting request. RLS policy may be blocking the insert.'),
    );

    debugPrint('[LeaveService] Step 2 done — insert OK');

    // Update pending days in balance
    if (balanceData != null) {
      debugPrint('[LeaveService] Step 3 — updating pending_days...');
      final currentPending =
          (balanceData['pending_days'] as num?)?.toDouble() ?? 0.0;
      await _supabase
          .from('leave_balances')
          .update({'pending_days': currentPending + totalDays})
          .eq('employee_id', employeeId)
          .eq('leave_policy_id', leavePolicyId)
          .eq('year', year)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception('Timed out updating balance.'),
          );
      debugPrint('[LeaveService] Step 3 done');
    }
  }

  // ── Cancel a pending leave request ────────────────────────────────────────
  Future<void> cancelRequest(String requestId, String employeeId) async {
    final requestData = await _supabase
        .from('leave_requests')
        .select()
        .eq('id', requestId)
        .eq('employee_id', employeeId)
        .maybeSingle();

    if (requestData == null) throw Exception('Request not found.');
    if (requestData['status'] != 'pending') {
      throw Exception('Only pending requests can be cancelled.');
    }

    await _supabase
        .from('leave_requests')
        .update({'status': 'cancelled'}).eq('id', requestId);

    // Return pending days to balance
    final year = DateTime.now().year;
    final totalDays = (requestData['total_days'] as num?)?.toDouble() ?? 0.0;
    final balanceData = await _supabase
        .from('leave_balances')
        .select()
        .eq('employee_id', employeeId)
        .eq('leave_policy_id', requestData['leave_policy_id'])
        .eq('year', year)
        .maybeSingle();

    if (balanceData != null) {
      final currentPending =
          (balanceData['pending_days'] as num?)?.toDouble() ?? 0.0;
      await _supabase
          .from('leave_balances')
          .update(
              {'pending_days': (currentPending - totalDays).clamp(0, 9999)})
          .eq('employee_id', employeeId)
          .eq('leave_policy_id', requestData['leave_policy_id'])
          .eq('year', year);
    }
  }

  // ── Upload leave attachment to Supabase Storage ───────────────────────────
  Future<String> uploadAttachment({
    required String employeeId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'bin';
    final storagePath =
        '$employeeId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    debugPrint('[LeaveService] Uploading attachment: $storagePath (${bytes.length} bytes)');

    try {
      await _supabase.storage
          .from('leave-attachments')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: _mimeType(ext)),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception(
                'Upload timed out. Check your internet connection.'),
          );
    } on StorageException catch (e) {
      debugPrint('[LeaveService] Storage error: ${e.message} (status: ${e.statusCode})');
      throw Exception('Upload failed: ${e.message}');
    }

    debugPrint('[LeaveService] Upload done — getting public URL');

    return _supabase.storage
        .from('leave-attachments')
        .getPublicUrl(storagePath);
  }

  String _mimeType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  // ── Calculate total working days (Mon–Fri, inclusive) ─────────────────────
  static double calculateDays(DateTime start, DateTime end, bool isHalfDay) {
    if (isHalfDay) return 0.5;
    int count = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(last)) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count.toDouble();
  }
}
