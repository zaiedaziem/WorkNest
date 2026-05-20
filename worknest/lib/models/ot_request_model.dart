class OtRequestModel {
  final String id;
  final String companyId;
  final String employeeId;
  final String date; // "yyyy-MM-dd"
  final String startTime; // "HH:mm:ss"
  final String endTime; // "HH:mm:ss"
  final String reason;
  final String otType; // weekday / restday / holiday
  final String status; // pending / approved / rejected
  final String? hrRemarks;
  final DateTime createdAt;

  OtRequestModel({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.otType,
    required this.status,
    this.hrRemarks,
    required this.createdAt,
  });

  double get otHours {
    try {
      final s = startTime.split(':');
      final e = endTime.split(':');
      final startM = int.parse(s[0]) * 60 + int.parse(s[1]);
      final endM = int.parse(e[0]) * 60 + int.parse(e[1]);
      return (endM - startM) / 60.0;
    } catch (_) {
      return 0;
    }
  }

  String get displayDate {
    try {
      final p = date.split('-');
      final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return date;
    }
  }

  String get displayStartTime =>
      startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
  String get displayEndTime =>
      endTime.length >= 5 ? endTime.substring(0, 5) : endTime;

  factory OtRequestModel.fromMap(Map<String, dynamic> map) {
    return OtRequestModel(
      id: map['Id']?.toString() ?? map['id']?.toString() ?? '',
      companyId:
          map['CompanyId']?.toString() ?? map['company_id']?.toString() ?? '',
      employeeId:
          map['EmployeeId']?.toString() ?? map['employee_id']?.toString() ?? '',
      date: map['Date']?.toString() ?? map['date']?.toString() ?? '',
      startTime:
          map['StartTime']?.toString() ??
          map['start_time']?.toString() ??
          '00:00:00',
      endTime:
          map['EndTime']?.toString() ??
          map['end_time']?.toString() ??
          '00:00:00',
      reason: map['Reason']?.toString() ?? map['reason']?.toString() ?? '',
      otType:
          map['OtType']?.toString() ?? map['ot_type']?.toString() ?? 'weekday',
      status:
          map['Status']?.toString() ?? map['status']?.toString() ?? 'pending',
      hrRemarks: map['HrRemarks']?.toString() ?? map['hr_remarks']?.toString(),
      createdAt:
          DateTime.tryParse(
            map['CreatedAt']?.toString() ?? map['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
