class CompanyModel {
  final String id;
  final String name;
  final String companyCode;
  final bool locationEnabled;
  final double? officeLat;
  final double? officeLng;
  final int officeRadius;
  final int workStartHour;
  final int workStartMinute;
  final int workEndHour;
  final int workEndMinute;

  CompanyModel({
    required this.id,
    required this.name,
    required this.companyCode,
    this.locationEnabled = false,
    this.officeLat,
    this.officeLng,
    this.officeRadius = 100,
    this.workStartHour = 9,
    this.workStartMinute = 0,
    this.workEndHour = 18,
    this.workEndMinute = 0,
  });

  bool get hasLocation => officeLat != null && officeLng != null;

  /// e.g. "09:00 AM"
  String get workStartTimeText => _formatTime(workStartHour, workStartMinute);

  /// e.g. "06:00 PM"
  String get workEndTimeText => _formatTime(workEndHour, workEndMinute);

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  /// True if the given [hour]:[minute] falls within office hours
  /// (workStart <= time < workEnd). Used to restrict OT requests to
  /// outside office hours only.
  bool isWithinOfficeHours(int hour, int minute) {
    final minutesOfDay = hour * 60 + minute;
    final start = workStartHour * 60 + workStartMinute;
    final end = workEndHour * 60 + workEndMinute;
    return minutesOfDay >= start && minutesOfDay < end;
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: (map['id'] ?? '').toString(),
      name: map['name'] ?? '',
      companyCode: map['companyCode'] ?? map['company_code'] ?? '',
      locationEnabled: map['locationEnabled'] ?? map['location_enabled'] ?? false,
      officeLat: (map['officeLat'] ?? map['office_lat'] as num?)?.toDouble(),
      officeLng: (map['officeLng'] ?? map['office_lng'] as num?)?.toDouble(),
      officeRadius: map['officeRadius'] ?? map['office_radius'] ?? 100,
      workStartHour: _parseTimeHour(map['work_start_time']),
      workStartMinute: _parseTimeMinute(map['work_start_time']),
      workEndHour: _parseTimeHour(map['work_end_time'], fallback: 18),
      workEndMinute: _parseTimeMinute(map['work_end_time']),
    );
  }

  // Parse "09:00:00" or "09:00" → hour int
  static int _parseTimeHour(dynamic value, {int fallback = 9}) {
    if (value == null) return fallback;
    final parts = value.toString().split(':');
    return int.tryParse(parts[0]) ?? fallback;
  }

  // Parse "09:00:00" or "09:00" → minute int
  static int _parseTimeMinute(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    final parts = value.toString().split(':');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? fallback : fallback;
  }
}
