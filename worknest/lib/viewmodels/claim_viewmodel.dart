import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';
import '../models/claim_model.dart';
import '../services/claim_service.dart';

class ClaimViewModel extends ChangeNotifier {
  final UserModel user;
  final CompanyModel company;
  final ClaimService _service = ClaimService();

  List<ClaimModel> _history = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  ClaimViewModel({required this.user, required this.company});

  List<ClaimModel> get history     => _history;
  bool get isLoading               => _isLoading;
  String? get errorMessage         => _errorMessage;
  String? get successMessage       => _successMessage;

  // Counts
  int get pendingCount  => _history.where((c) => c.status == 'pending').length;
  int get approvedCount => _history.where((c) => c.status == 'approved').length;
  double get totalApproved => _history
      .where((c) => c.status == 'approved')
      .fold(0, (sum, c) => sum + c.amount);

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _history = await _service.getHistory(user.id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitClaim({
    required String claimType,
    required String title,
    String? description,
    required DateTime claimDate,
    required double amount,
    double? suggestedAmount,
    String? receiptUrl,
    String? transportMode,
    double? distanceKm,
    double? tollAmount,
    double? parkingAmount,
    String? destinationType,
    double? distanceFromOfficeKm,
    int? numberOfNights,
    bool? hasAccommodationReceipt,
    int? numberOfDays,
    bool? isOvernightStay,
    DateTime? returnDateTime,
    double? overseasTransportCost,
    double? overseasPhoneCost,
    double? overseasLaundryCost,
    double? overseasOtherCost,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.submitClaim(
        employeeId:   user.id,
        companyId:    company.id,
        claimType:    claimType,
        title:        title,
        description:  description,
        claimDate:    claimDate,
        amount:       amount,
        suggestedAmount: suggestedAmount,
        receiptUrl:      receiptUrl,
        transportMode:   transportMode,
        distanceKm:      distanceKm,
        tollAmount:      tollAmount,
        parkingAmount:   parkingAmount,
        destinationType:      destinationType,
        distanceFromOfficeKm: distanceFromOfficeKm,
        numberOfNights:          numberOfNights,
        hasAccommodationReceipt: hasAccommodationReceipt,
        numberOfDays:    numberOfDays,
        isOvernightStay: isOvernightStay,
        returnDateTime:  returnDateTime,
        overseasTransportCost: overseasTransportCost,
        overseasPhoneCost:     overseasPhoneCost,
        overseasLaundryCost:   overseasLaundryCost,
        overseasOtherCost:     overseasOtherCost,
      );
      _successMessage = 'Claim submitted successfully!';
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
