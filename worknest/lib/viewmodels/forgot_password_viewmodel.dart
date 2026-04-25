import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum ForgotPasswordStep { requestOtp, verifyOtp, resetPassword, done }

class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  ForgotPasswordStep _step = ForgotPasswordStep.requestOtp;
  bool _isLoading = false;
  String? _errorMessage;
  String _email = '';

  ForgotPasswordStep get step => _step;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get email => _email;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Step 1 — look up email by Company Code + Employee ID, then send OTP
  Future<void> requestOtp({
    required String companyCode,
    required String employeeId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final email = await _authService.sendOtpByCredentials(
        companyCode: companyCode,
        employeeId: employeeId,
      );
      _email = email;
      _step = ForgotPasswordStep.verifyOtp;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// For Step 2 subtitle — returns something like `j***n@company.com`
  /// so we don't leak the full email address to whoever is holding the phone.
  String get maskedEmail {
    if (_email.isEmpty) return '';
    final at = _email.indexOf('@');
    if (at <= 1) return _email;
    final name = _email.substring(0, at);
    final domain = _email.substring(at);
    if (name.length <= 2) return '${name[0]}*$domain';
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}$domain';
  }

  // Step 2 — verify OTP
  Future<void> verifyOtp(String otpCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.verifyOtp(_email, otpCode);
      _step = ForgotPasswordStep.resetPassword;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Step 3 — reset password
  Future<bool> resetPassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(newPassword);
      _step = ForgotPasswordStep.done;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resend OTP
  Future<void> resendOtp() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendOtp(_email);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void goBack() {
    if (_step == ForgotPasswordStep.verifyOtp) {
      _step = ForgotPasswordStep.requestOtp;
    } else if (_step == ForgotPasswordStep.resetPassword) {
      _step = ForgotPasswordStep.verifyOtp;
    }
    _errorMessage = null;
    notifyListeners();
  }
}
