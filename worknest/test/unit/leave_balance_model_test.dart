import 'package:flutter_test/flutter_test.dart';
import 'package:worknest/models/leave_balance_model.dart';

// Helper — build LeaveBalanceModel with custom day values
LeaveBalanceModel makeBalance({
  double totalDays   = 14.0,
  double usedDays    = 0.0,
  double pendingDays = 0.0,
}) {
  return LeaveBalanceModel(
    id: 'test-id',
    employeeId: 'emp-1',
    leavePolicyId: 'policy-1',
    leavePolicyName: 'Annual Leave',
    leavePolicyCode: 'AL',
    year: 2025,
    totalDays: totalDays,
    usedDays: usedDays,
    pendingDays: pendingDays,
  );
}

void main() {

  // ─────────────────────────────────────────────────────────────────────────
  // remainingDays = totalDays - usedDays - pendingDays
  // ─────────────────────────────────────────────────────────────────────────
  group('LeaveBalanceModel.remainingDays', () {

    test('fresh balance — nothing used: 14 - 0 - 0 = 14.0', () {
      expect(makeBalance(totalDays: 14, usedDays: 0, pendingDays: 0).remainingDays, 14.0);
    });

    test('3 days used: 14 - 3 - 0 = 11.0', () {
      expect(makeBalance(totalDays: 14, usedDays: 3, pendingDays: 0).remainingDays, 11.0);
    });

    test('3 used + 2 pending: 14 - 3 - 2 = 9.0', () {
      expect(makeBalance(totalDays: 14, usedDays: 3, pendingDays: 2).remainingDays, 9.0);
    });

    test('fully used: 14 - 14 - 0 = 0.0', () {
      expect(makeBalance(totalDays: 14, usedDays: 14, pendingDays: 0).remainingDays, 0.0);
    });

    test('over-used (edge case): 14 - 15 - 0 = -1.0', () {
      // Should not happen in practice but model must not crash
      expect(makeBalance(totalDays: 14, usedDays: 15, pendingDays: 0).remainingDays, -1.0);
    });

    test('half-day values: 14 - 0.5 - 0.5 = 13.0', () {
      expect(makeBalance(totalDays: 14, usedDays: 0.5, pendingDays: 0.5).remainingDays, 13.0);
    });

    test('sick leave with 0 total: 0 - 0 - 0 = 0.0', () {
      expect(makeBalance(totalDays: 0, usedDays: 0, pendingDays: 0).remainingDays, 0.0);
    });

  });

}
