import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';
import '../services/auth_service.dart';

enum LoginState { idle, loading, success, error }

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  LoginState _state = LoginState.idle;
  String? _errorMessage;
  UserModel? _user;
  CompanyModel? _company;

  LoginState get state => _state;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  CompanyModel? get company => _company;
  bool get isLoading => _state == LoginState.loading;

  Future<void> login({
    required String companyCode,
    required String employeeId,
    required String password,
  }) async {
    _state = LoginState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        companyCode: companyCode,
        employeeId: employeeId,
        password: password,
      );

      _user = result['user'] as UserModel;
      _company = result['company'] as CompanyModel;
      _state = LoginState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = LoginState.error;
    }

    notifyListeners();
  }

  void reset() {
    _state = LoginState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
