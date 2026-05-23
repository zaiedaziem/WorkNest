class PayslipModel {
  final String id;
  final int year;
  final int month;
  final double basicSalary;
  final double transportAllowance;
  final double mealAllowance;
  final double housingAllowance;
  final double otherAllowance;
  final double otPay;
  final double grossPay;
  final double epfEmployee;
  final double socsoEmployee;
  final double eisEmployee;
  final double attendanceDeduction;
  final double claimsTotal;
  final double totalDeductions;
  final double netPay;
  final String status;
  final String? hrRemarks;

  // Employee & company info (populated by service)
  final String empName;
  final String empIdStr;
  final String companyName;
  final String companyAddress;
  final String companyPhone;
  final String companyEmail;

  PayslipModel({
    required this.id,
    required this.year,
    required this.month,
    required this.basicSalary,
    required this.transportAllowance,
    required this.mealAllowance,
    required this.housingAllowance,
    required this.otherAllowance,
    required this.otPay,
    required this.grossPay,
    required this.epfEmployee,
    required this.socsoEmployee,
    required this.eisEmployee,
    required this.attendanceDeduction,
    required this.claimsTotal,
    required this.totalDeductions,
    required this.netPay,
    required this.status,
    this.hrRemarks,
    this.empName = '',
    this.empIdStr = '-',
    this.companyName = '',
    this.companyAddress = '',
    this.companyPhone = '',
    this.companyEmail = '',
  });

  factory PayslipModel.fromMap(
    Map<String, dynamic> m, {
    String empName = '',
    String empIdStr = '-',
    String companyName = '',
    String companyAddress = '',
    String companyPhone = '',
    String companyEmail = '',
  }) {
    double d(String key) =>
        (m[key] ?? m[key.toLowerCase()] ?? 0).toDouble();

    return PayslipModel(
      id:                  m['Id']?.toString()    ?? m['id']?.toString() ?? '',
      year:                (m['Year']             ?? m['year']           ?? 0) as int,
      month:               (m['Month']            ?? m['month']          ?? 0) as int,
      basicSalary:         d('BasicSalary'),
      transportAllowance:  d('TransportAllowance'),
      mealAllowance:       d('MealAllowance'),
      housingAllowance:    d('HousingAllowance'),
      otherAllowance:      d('OtherAllowance'),
      otPay:               d('OtPay'),
      grossPay:            d('GrossPay'),
      epfEmployee:         d('EpfEmployee'),
      socsoEmployee:       d('SocsoEmployee'),
      eisEmployee:         d('EisEmployee'),
      attendanceDeduction: d('AttendanceDeduction'),
      claimsTotal:         d('ClaimsTotal'),
      totalDeductions:     d('TotalDeductions'),
      netPay:              d('NetPay'),
      status:              m['Status']?.toString() ?? m['status']?.toString() ?? '',
      hrRemarks:           m['HrRemarks']?.toString() ?? m['hr_remarks']?.toString(),
      empName:             empName,
      empIdStr:            empIdStr,
      companyName:         companyName,
      companyAddress:      companyAddress,
      companyPhone:        companyPhone,
      companyEmail:        companyEmail,
    );
  }

  String get monthName {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month]} $year';
  }

  String get monthShort {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month]} $year';
  }

  double get allowanceTotal =>
      transportAllowance + mealAllowance + housingAllowance + otherAllowance;

  double get totalEarnings => grossPay + claimsTotal;
}
