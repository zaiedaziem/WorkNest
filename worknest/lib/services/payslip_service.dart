import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payslip_model.dart';

class PayslipService {
  final _db = Supabase.instance.client;

  Future<List<PayslipModel>> getAll(String userId) async {
    // 1. Fetch employee's user info
    String empName = '';
    String empIdStr = '-';
    String companyName = '';
    String companyAddress = '';
    String companyPhone = '';
    String companyEmail = '';

    try {
      final userRow = await _db
          .from('users')
          .select('first_name, last_name, employee_id, company_id')
          .eq('id', userId)
          .single();

      empName = '${userRow['first_name'] ?? ''} ${userRow['last_name'] ?? ''}'.trim();
      empIdStr = userRow['employee_id']?.toString() ?? '-';

      final companyId = userRow['company_id']?.toString();
      if (companyId != null) {
        final companyRow = await _db
            .from('companies')
            .select('name, address, phone, email')
            .eq('id', companyId)
            .single();

        companyName    = companyRow['name']?.toString()    ?? '';
        companyAddress = companyRow['address']?.toString() ?? '';
        companyPhone   = companyRow['phone']?.toString()   ?? '';
        companyEmail   = companyRow['email']?.toString()   ?? '';
      }
    } catch (_) {
      // Non-fatal — payslip data still loads without personal info
    }

    // 2. Fetch payroll records
    final data = await _db
        .from('PayrollRecords')
        .select()
        .eq('EmployeeId', userId)
        .eq('Status', 'finalized')
        .order('Year', ascending: false)
        .order('Month', ascending: false)
        .limit(24)
        .timeout(const Duration(seconds: 15));

    return (data as List)
        .map((e) => PayslipModel.fromMap(
              e,
              empName:        empName,
              empIdStr:       empIdStr,
              companyName:    companyName,
              companyAddress: companyAddress,
              companyPhone:   companyPhone,
              companyEmail:   companyEmail,
            ))
        .toList();
  }
}
