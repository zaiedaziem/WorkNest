import 'package:flutter/material.dart';
import '../models/ot_request_model.dart';
import '../services/ot_request_service.dart';

class OtRequestViewModel extends ChangeNotifier {
  final String userId;
  final String companyId;
  final _service = OtRequestService();

  List<OtRequestModel> _requests = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  OtRequestViewModel({required this.userId, required this.companyId}) {
    load();
  }

  List<OtRequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  int get pendingCount => _requests.where((r) => r.status == 'pending').length;
  int get approvedCount =>
      _requests.where((r) => r.status == 'approved').length;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _requests = await _service.getAll(userId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submit({
    required String date,
    required String startTime,
    required String endTime,
    required String reason,
    required String otType,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _service.submit(
        companyId: companyId,
        employeeId: userId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
        otType: otType,
      );
      await load();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
