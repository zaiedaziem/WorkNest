import 'package:flutter/material.dart';
import '../models/payslip_model.dart';
import '../services/payslip_service.dart';

class PayslipViewModel extends ChangeNotifier {
  final String userId;
  final _service = PayslipService();

  List<PayslipModel> _payslips = [];
  bool _isLoading = false;
  String? _error;

  PayslipViewModel({required this.userId}) {
    load();
  }

  List<PayslipModel> get payslips  => _payslips;
  bool               get isLoading => _isLoading;
  String?            get error     => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _payslips = await _service.getAll(userId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
