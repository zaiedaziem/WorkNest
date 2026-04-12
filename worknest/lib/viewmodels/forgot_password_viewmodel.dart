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

  // Step 1 — send OTP to email
  Future<void> requestOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendOtp(email);
      _email = email.trim();
      _step = ForgotPasswordStep.verifyOtp;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
