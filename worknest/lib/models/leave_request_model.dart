class LeaveRequestModel {
  final String id;
  final String employeeId;
  final String leavePolicyId;
  final String leavePolicyName; // joined from leave_policies
  final String leavePolicyCode; // joined from leave_policies
  final DateTime startDate;
  final DateTime endDate;
  final bool isHalfDay;
  final String? halfDayPeriod; // morning / afternoon
  final double totalDays;
  final String? reason;
  final String? attachmentUrl;
  final String status; // pending / approved / rejected / cancelled
  final String? hrRemarks;
  final DateTime createdAt;

  LeaveRequestModel({
    required this.id,
    required this.employeeId,
    required this.leavePolicyId,
    required this.leavePolicyName,
    required this.leavePolicyCode,
    required this.startDate,
    required this.endDate,
    required this.isHalfDay,
    this.halfDayPeriod,
    required this.totalDays,
    this.reason,
    this.attachmentUrl,
    required this.status,
    this.hrRemarks,
    required this.createdAt,
  });

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map) {
    return LeaveRequestModel(
      id: map['id']?.toString() ?? '',
      employeeId: map['employee_id']?.toString() ?? '',
      leavePolicyId: map['leave_policy_id']?.toString() ?? '',
      leavePolicyName: map['leave_policies']?['name']?.toString() ?? '',
      leavePolicyCode: map['leave_policies']?['code']?.toString() ?? '',
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      isHalfDay: map['is_half_day'] ?? false,
      halfDayPeriod: map['half_day_period']?.toString(),
      totalDays: (map['total_days'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason']?.toString(),
      attachmentUrl: map['attachment_url']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      hrRemarks: map['hr_remarks']?.toString(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
