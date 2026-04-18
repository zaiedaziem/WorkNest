import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';
import '../models/leave_policy_model.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_request_model.dart';
import '../services/leave_service.dart';

class LeaveViewModel extends ChangeNotifier {
  final UserModel user;
  final CompanyModel company;
  final LeaveService _service = LeaveService();

  List<LeavePolicyModel> _policies = [];
  List<LeaveBalanceModel> _balances = [];
  List<LeaveRequestModel> _history = [];

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  LeaveViewModel({required this.user, required this.company});

  List<LeavePolicyModel> get policies => _policies;
  List<LeaveBalanceModel> get balances => _balances;
  List<LeaveRequestModel> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getPolicies(company.id),
        _service.getBalances(user.id),
        _service.getHistory(user.id),
      ]);
      _policies = results[0] as List<LeavePolicyModel>;
      _balances = results[1] as List<LeaveBalanceModel>;
      _history = results[2] as List<LeaveRequestModel>;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  LeaveBalanceModel? getBalanceForPolicy(String policyId) {
    try {
      return _balances.firstWhere((b) => b.leavePolicyId == policyId);
    } catch (_) {
      return null;
    }
  }

  Future<void> submitRequest({
    required String leavePolicyId,
    required DateTime startDate,
    required DateTime endDate,
    required bool isHalfDay,
    String? halfDayPeriod,
    String? reason,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final totalDays =
          LeaveService.calculateDays(startDate, endDate, isHalfDay);

      await _service.submitRequest(
        employeeId: user.id,
        companyId: company.id,
        leavePolicyId: leavePolicyId,
        startDate: startDate,
        endDate: endDate,
        isHalfDay: isHalfDay,
        halfDayPeriod: halfDayPeriod,
        totalDays: totalDays,
        reason: reason,
      );

      _successMessage = 'Leave request submitted successfully!';
      await loadData(); // Refresh balances and history
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelRequest(String requestId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.cancelRequest(requestId, user.id);
      _successMessage = 'Leave request cancelled.';
      await loadData();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }
}
