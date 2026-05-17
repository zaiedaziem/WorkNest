class ClaimModel {
  final String id;
  final String employeeId;
  final String companyId;

  // Claim basics
  final String claimType;   // travel | accommodation | subsistence | other
  final String title;
  final String? description;
  final DateTime claimDate;

  // Amounts
  final double amount;          // what employee claims
  final double? suggestedAmount; // policy-calculated

  // Travel
  final String? transportMode;  // own_vehicle | flight | public_transport
  final double? distanceKm;
  final double? tollAmount;
  final double? parkingAmount;

  // Accommodation & Subsistence shared
  final String? destinationType;       // domestic | southeast_asia | other_foreign
  final double? distanceFromOfficeKm;

  // Accommodation
  final int? numberOfNights;
  final bool? hasAccommodationReceipt;

  // Subsistence
  final int? numberOfDays;
  final bool? isOvernightStay;
  final DateTime? returnDateTime;

  // Overseas — 13.5
  final double? overseasTransportCost;
  final double? overseasPhoneCost;
  final double? overseasLaundryCost;
  final double? overseasOtherCost;

  // Receipt (optional, uploaded by employee)
  final String? receiptUrl;

  // Status
  final String status; // pending | approved | rejected
  final double? approvedAmount; // HR-set reimbursement amount
  final String? rejectionReason;
  final DateTime createdAt;

  ClaimModel({
    required this.id,
    required this.employeeId,
    required this.companyId,
    required this.claimType,
    required this.title,
    this.description,
    required this.claimDate,
    required this.amount,
    this.suggestedAmount,
    this.transportMode,
    this.distanceKm,
    this.tollAmount,
    this.parkingAmount,
    this.destinationType,
    this.distanceFromOfficeKm,
    this.numberOfNights,
    this.hasAccommodationReceipt,
    this.numberOfDays,
    this.isOvernightStay,
    this.returnDateTime,
    this.overseasTransportCost,
    this.overseasPhoneCost,
    this.overseasLaundryCost,
    this.overseasOtherCost,
    this.receiptUrl,
    required this.status,
    this.approvedAmount,
    this.rejectionReason,
    required this.createdAt,
  });

  factory ClaimModel.fromMap(Map<String, dynamic> m) {
    return ClaimModel(
      id:          m['Id']?.toString() ?? '',
      employeeId:  m['EmployeeId']?.toString() ?? '',
      companyId:   m['CompanyId']?.toString() ?? '',
      claimType:   m['ClaimType']?.toString() ?? 'other',
      title:       m['Title']?.toString() ?? '',
      description: m['Description']?.toString(),
      claimDate:   DateTime.tryParse(m['ClaimDate']?.toString() ?? '') ?? DateTime.now(),
      amount:      (m['Amount'] as num?)?.toDouble() ?? 0,
      suggestedAmount: (m['SuggestedAmount'] as num?)?.toDouble(),
      transportMode:   m['TransportMode']?.toString(),
      distanceKm:      (m['DistanceKm'] as num?)?.toDouble(),
      tollAmount:      (m['TollAmount'] as num?)?.toDouble(),
      parkingAmount:   (m['ParkingAmount'] as num?)?.toDouble(),
      destinationType:    m['DestinationType']?.toString(),
      distanceFromOfficeKm: (m['DistanceFromOfficeKm'] as num?)?.toDouble(),
      numberOfNights:      (m['NumberOfNights'] as num?)?.toInt(),
      hasAccommodationReceipt: m['HasAccommodationReceipt'] as bool?,
      numberOfDays:    (m['NumberOfDays'] as num?)?.toInt(),
      isOvernightStay: m['IsOvernightStay'] as bool?,
      returnDateTime:  m['ReturnDateTime'] != null
          ? DateTime.tryParse(m['ReturnDateTime'].toString())
          : null,
      overseasTransportCost: (m['OverseasTransportCost'] as num?)?.toDouble(),
      overseasPhoneCost:     (m['OverseasPhoneCost'] as num?)?.toDouble(),
      overseasLaundryCost:   (m['OverseasLaundryCost'] as num?)?.toDouble(),
      overseasOtherCost:     (m['OverseasOtherCost'] as num?)?.toDouble(),
      receiptUrl:      m['ReceiptUrl']?.toString(),
      status:          m['Status']?.toString() ?? 'pending',
      approvedAmount:  (m['ApprovedAmount'] as num?)?.toDouble(),
      rejectionReason: m['RejectionReason']?.toString(),
      createdAt: DateTime.tryParse(m['CreatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Human-readable claim type label
  String get typeLabel => switch (claimType) {
    'travel'        => 'Travel',
    'accommodation' => 'Accommodation',
    'subsistence'   => 'Subsistence',
    'overseas'      => 'Overseas',
    _               => 'Other',
  };

  /// Icon for claim type
  String get typeIconName => switch (claimType) {
    'travel'        => 'car',
    'accommodation' => 'building',
    'subsistence'   => 'food',
    _               => 'receipt',
  };

  /// Whether the claimed amount exceeds the policy suggestion
  bool get exceedsPolicy =>
      suggestedAmount != null && amount > suggestedAmount!;
}

// ── Policy rate calculator (mirrors C# ClaimPolicyRates) ─────────────────────

class ClaimPolicyRates {
  static const double mileageFirst200 = 0.70;
  static const double mileageAbove200 = 0.55;

  static double calculateMileage(double km) {
    if (km <= 200) return km * mileageFirst200;
    return (200 * mileageFirst200) + ((km - 200) * mileageAbove200);
  }

  static double calculateAccommodation({
    required String grade,
    required bool hasReceipt,
    required int nights,
    required String destination,
  }) {
    // Overseas → actual cost, no fixed rate
    if (destination == 'southeast_asia' || destination == 'other_foreign') return 0;

    final rate = grade == 'management'
        ? (hasReceipt ? 300.0 : 80.0)
        : (hasReceipt ? 250.0 : 60.0);
    return rate * nights;
  }

  static double calculateSubsistence({
    required String grade,
    required String destination,
    required int fullDays,
    required bool isOvernightStay,
  }) {
    double daily;
    if (grade == 'management') {
      daily = switch (destination) {
        'southeast_asia' => 200.0,
        'other_foreign'  => 300.0,
        _                => 100.0,
      };
    } else {
      daily = switch (destination) {
        'southeast_asia' => 140.0,
        'other_foreign'  => 210.0,
        _                => 70.0,
      };
    }
    // If not overnight — half rate
    final effectiveDays = isOvernightStay ? fullDays.toDouble() : fullDays * 0.5;
    return daily * effectiveDays;
  }
}
