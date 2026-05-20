import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ot_request_model.dart';

class OtRequestService {
  final _db = Supabase.instance.client;
  static const _table = 'OtRequests';

  String _uuid() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${bytes.sublist(0, 4).map(hex).join()}-'
        '${bytes.sublist(4, 6).map(hex).join()}-'
        '${bytes.sublist(6, 8).map(hex).join()}-'
        '${bytes.sublist(8, 10).map(hex).join()}-'
        '${bytes.sublist(10).map(hex).join()}';
  }

  Future<List<OtRequestModel>> getAll(String userId) async {
    final data = await _db
        .from(_table)
        .select()
        .eq('EmployeeId', userId)
        .order('CreatedAt', ascending: false)
        .limit(30)
        .timeout(const Duration(seconds: 15));
    return (data as List).map((e) => OtRequestModel.fromMap(e)).toList();
  }

  Future<void> submit({
    required String companyId,
    required String employeeId,
    required String date,
    required String startTime,
    required String endTime,
    required String reason,
    required String otType,
  }) async {
    await _db
        .from(_table)
        .insert({
          'Id': _uuid(),
          'CompanyId': companyId,
          'EmployeeId': employeeId,
          'Date': date,
          'StartTime': startTime,
          'EndTime': endTime,
          'Reason': reason,
          'OtType': otType,
          'Status': 'pending',
          'CreatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .timeout(const Duration(seconds: 15));
  }
}
