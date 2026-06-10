import 'package:flutter_test/flutter_test.dart';
import 'package:worknest/models/payslip_model.dart';

// Helper — build PayslipModel with custom values
PayslipModel makePayslip({
  int year  = 2025,
  int month = 6,
  double basicSalary        = 3000.0,
  double transportAllowance = 0.0,
  double mealAllowance      = 0.0,
  double housingAllowance   = 0.0,
  double otherAllowance     = 0.0,
  double otPay              = 0.0,
  double grossPay           = 3000.0,
  double epfEmployee        = 330.0,
  double socsoEmployee      = 15.0,
  double eisEmployee        = 6.0,
  double attendanceDeduction = 0.0,
  double claimsTotal        = 0.0,
  double totalDeductions    = 351.0,
  double netPay             = 2649.0,
  String status             = 'finalized',
}) {
  return PayslipModel(
    id: 'test-id',
    year: year,
    month: month,
    basicSalary: basicSalary,
    transportAllowance: transportAllowance,
    mealAllowance: mealAllowance,
    housingAllowance: housingAllowance,
    otherAllowance: otherAllowance,
    otPay: otPay,
    grossPay: grossPay,
    epfEmployee: epfEmployee,
    socsoEmployee: socsoEmployee,
    eisEmployee: eisEmployee,
    attendanceDeduction: attendanceDeduction,
    claimsTotal: claimsTotal,
    totalDeductions: totalDeductions,
    netPay: netPay,
    status: status,
  );
}

void main() {

  // ─────────────────────────────────────────────────────────────────────────
  // 1. monthName — "January 2025" format
  // ─────────────────────────────────────────────────────────────────────────
  group('PayslipModel.monthName', () {

    test('month 1 → "January 2025"', () {
      expect(makePayslip(year: 2025, month: 1).monthName, 'January 2025');
    });

    test('month 6 → "June 2025"', () {
      expect(makePayslip(year: 2025, month: 6).monthName, 'June 2025');
    });

    test('month 12 → "December 2024"', () {
      expect(makePayslip(year: 2024, month: 12).monthName, 'December 2024');
    });

    test('each month has the correct name', () {
      const expected = [
        'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August',
        'September', 'October', 'November', 'December',
      ];
      for (int i = 1; i <= 12; i++) {
        expect(
          makePayslip(year: 2025, month: i).monthName,
          '${expected[i - 1]} 2025',
          reason: 'Month $i should be ${expected[i - 1]}',
        );
      }
    });

  });


  // ─────────────────────────────────────────────────────────────────────────
  // 2. monthShort — "Jun 2025" format
  // ─────────────────────────────────────────────────────────────────────────
  group('PayslipModel.monthShort', () {

    test('month 1 → "Jan 2025"', () {
      expect(makePayslip(year: 2025, month: 1).monthShort, 'Jan 2025');
    });

    test('month 6 → "Jun 2025"', () {
      expect(makePayslip(year: 2025, month: 6).monthShort, 'Jun 2025');
    });

    test('month 12 → "Dec 2025"', () {
      expect(makePayslip(year: 2025, month: 12).monthShort, 'Dec 2025');
    });

  });


  // ─────────────────────────────────────────────────────────────────────────
  // 3. allowanceTotal — sum of all 4 allowances
  // ─────────────────────────────────────────────────────────────────────────
  group('PayslipModel.allowanceTotal', () {

    test('all zero → 0.0', () {
      expect(
        makePayslip(
          transportAllowance: 0,
          mealAllowance: 0,
          housingAllowance: 0,
          otherAllowance: 0,
        ).allowanceTotal,
        0.0,
      );
    });

    test('transport=200, meal=100, housing=300, other=50 → 650.0', () {
      expect(
        makePayslip(
          transportAllowance: 200,
          mealAllowance: 100,
          housingAllowance: 300,
          otherAllowance: 50,
        ).allowanceTotal,
        650.0,
      );
    });

    test('only transport allowance: 300 → 300.0', () {
      expect(
        makePayslip(
          transportAllowance: 300,
          mealAllowance: 0,
          housingAllowance: 0,
          otherAllowance: 0,
        ).allowanceTotal,
        300.0,
      );
    });

  });


  // ─────────────────────────────────────────────────────────────────────────
  // 4. totalEarnings — grossPay + claimsTotal
  // ─────────────────────────────────────────────────────────────────────────
  group('PayslipModel.totalEarnings', () {

    test('no claims: grossPay 3000 + 0 = 3000.0', () {
      expect(
        makePayslip(grossPay: 3000, claimsTotal: 0).totalEarnings,
        3000.0,
      );
    });

    test('with claims: grossPay 3000 + claims 250 = 3250.0', () {
      expect(
        makePayslip(grossPay: 3000, claimsTotal: 250).totalEarnings,
        3250.0,
      );
    });

    test('grossPay 5000 + claims 150.50 = 5150.50', () {
      expect(
        makePayslip(grossPay: 5000, claimsTotal: 150.50).totalEarnings,
        closeTo(5150.50, 0.001),
      );
    });

  });

}
