class LeaveBalanceModel {
  final String id;
  final String employeeId;
  final String leavePolicyId;
  final String leavePolicyName; // joined from leave_policies
  final String leavePolicyCode; // joined from leave_policies
  final int year;
  final double totalDays;
  final double usedDays;
  final double pendingDays;

  LeaveBalanceModel({
    required this.id,
    required this.employeeId,
    required this.leavePolicyId,
    required this.leavePolicyName,
    required this.leavePolicyCode,
    required this.year,
    required this.totalDays,
    required this.usedDays,
    required this.pendingDays,
  });

  double get remainingDays => totalDays - usedDays - pendingDays;

  factory LeaveBalanceModel.fromMap(Map<String, dynamic> map) {
    return LeaveBalanceModel(
      id: map['id']?.toString() ?? '',
      employeeId: map['employee_id']?.toString() ?? '',
      leavePolicyId: map['leave_policy_id']?.toString() ?? '',
      leavePolicyName: map['leave_policies']?['name']?.toString() ?? '',
      leavePolicyCode: map['leave_policies']?['code']?.toString() ?? '',
      year: map['year'] ?? DateTime.now().year,
      totalDays: (map['total_days'] as num?)?.toDouble() ?? 0.0,
      usedDays: (map['used_days'] as num?)?.toDouble() ?? 0.0,
      pendingDays: (map['pending_days'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
