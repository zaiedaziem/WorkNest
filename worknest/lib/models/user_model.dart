class UserModel {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String? email;
  final String role;
  final String companyId;

  UserModel({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.role,
    required this.companyId,
  });

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['id'] ?? '').toString(),
      // ASP.NET returns camelCase, Supabase returns snake_case — handle both
      employeeId: map['employeeId'] ?? map['employee_id'] ?? '',
      firstName: map['firstName'] ?? map['first_name'] ?? '',
      lastName: map['lastName'] ?? map['last_name'] ?? '',
      email: map['email'],
      role: map['role'] ?? 'employee',
      companyId: (map['companyId'] ?? map['company_id'] ?? '').toString(),
    );
  }
}
