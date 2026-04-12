class AttendanceModel {
  final String id;
  final String employeeId;
  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String type; // 'office' or 'wfh'
  final String status; // 'present', 'late', 'absent'
  final double? clockInLat;
  final double? clockInLng;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.date,
    this.clockIn,
    this.clockOut,
    required this.type,
    required this.status,
    this.clockInLat,
    this.clockInLng,
  });

  bool get isClockedIn => clockIn != null;
  bool get isClockedOut => clockOut != null;

  Duration? get duration {
    if (clockIn == null || clockOut == null) return null;
    return clockOut!.difference(clockIn!);
  }

  String get durationText {
    final d = duration;
    if (d == null) return '-';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] ?? '',
      employeeId: map['employee_id'] ?? '',
      date: DateTime.parse(map['date']),
      clockIn: map['clock_in'] != null ? DateTime.parse(map['clock_in']).toLocal() : null,
      clockOut: map['clock_out'] != null ? DateTime.parse(map['clock_out']).toLocal() : null,
      type: map['type'] ?? 'office',
      status: map['status'] ?? 'present',
      clockInLat: (map['clock_in_lat'] as num?)?.toDouble(),
      clockInLng: (map['clock_in_lng'] as num?)?.toDouble(),
    );
  }
}
