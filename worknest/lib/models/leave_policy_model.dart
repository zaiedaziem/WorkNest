class LeavePolicyModel {
  final String id;
  final String companyId;
  final String name;
  final String code;
  final String? description;
  final bool isPaid;
  final double defaultDays;
  final int applicableAfterMonths;
  final bool allowHalfDay;
  final bool requiresDocument;
  final String genderRestriction; // all / male / female
  final int? maxOccurrences;      // null = unlimited, 1 = once only, 5 = maternity
  final bool isActive;

  LeavePolicyModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    this.description,
    required this.isPaid,
    required this.defaultDays,
    required this.applicableAfterMonths,
    required this.allowHalfDay,
    required this.requiresDocument,
    required this.genderRestriction,
    this.maxOccurrences,
    required this.isActive,
  });

  factory LeavePolicyModel.fromMap(Map<String, dynamic> map) {
    return LeavePolicyModel(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      description: map['description']?.toString(),
      isPaid: map['is_paid'] ?? true,
      defaultDays: (map['default_days'] as num?)?.toDouble() ?? 0.0,
      applicableAfterMonths: map['applicable_after_months'] ?? 0,
      allowHalfDay: map['allow_half_day'] ?? false,
      requiresDocument: map['requires_document'] ?? false,
      genderRestriction: map['gender_restriction']?.toString() ?? 'all',
      maxOccurrences: map['max_occurrences'] as int?,
      isActive: map['is_active'] ?? true,
    );
  }
}
