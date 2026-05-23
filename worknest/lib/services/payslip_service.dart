import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payslip_model.dart';

class PayslipService {
  final _db = Supabase.instance.client;

  Future<List<PayslipModel>> getAll(String userId) async {
    final data = await _db
        .from('PayrollRecords')
        .select()
        .eq('EmployeeId', userId)
        .eq('Status', 'finalized')
        .order('Year', ascending: false)
        .order('Month', ascending: false)
        .limit(24)
        .timeout(const Duration(seconds: 15));

    return (data as List).map((e) => PayslipModel.fromMap(e)).toList();
  }
}
