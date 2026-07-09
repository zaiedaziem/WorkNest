import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // ── Login with Company Code + Employee ID + Password ───────────────────────
  Future<Map<String, dynamic>> login({
    required String companyCode,
    required String employeeId,
    required String password,
  }) async {
    // 1. Look up the email via a narrow RPC — this runs anonymously (before
    // auth), so it must NOT expose full row data under RLS. See
    // get_login_email() in Supabase.
    final email = await _supabase.rpc('get_login_email', params: {
      'p_company_code': companyCode,
      'p_employee_id': employeeId,
    }) as String?;

    if (email == null || email.isEmpty) {
      throw Exception('Company or Employee ID not found.');
    }

    // 2. Sign in with Supabase Auth using the email we found
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid')) {
        throw Exception('Incorrect password.');
      }
      throw Exception(e.message);
    }

    // 3. Now authenticated — fetch full company + user rows (RLS allows
    // this since the session is no longer anonymous).
    final companyData = await _supabase
        .from('companies')
        .select()
        .eq('company_code', companyCode.toLowerCase().trim())
        .eq('is_active', true)
        .maybeSingle();

    if (companyData == null) throw Exception('Company not found.');

    final userData = await _supabase
        .from('users')
        .select()
        .eq('company_id', companyData['id'])
        .eq('employee_id', employeeId.trim())
        .eq('role', 'employee')
        .eq('is_active', true)
        .maybeSingle();

    if (userData == null) throw Exception('Employee ID not found.');

    return {
      'user': UserModel.fromMap(userData),
      'company': CompanyModel.fromMap(companyData),
    };
  }

  // ── Forgot password: Step 1 — send OTP to email ────────────────────────────
  Future<void> sendOtp(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // ── Forgot password: Look up email by Company Code + Employee ID ──────────
  // Sends OTP to the looked-up email and returns that email (so the
  // ViewModel can show a masked version at Step 2).
  Future<String> sendOtpByCredentials({
    required String companyCode,
    required String employeeId,
  }) async {
    final email = await _supabase.rpc('get_login_email', params: {
      'p_company_code': companyCode,
      'p_employee_id': employeeId,
    }) as String?;

    if (email == null || email.isEmpty) {
      throw Exception('Company or Employee ID not found.');
    }

    await sendOtp(email);
    return email;
  }

  // ── Forgot password: Step 2 — verify OTP (signs user in) ──────────────────
  Future<void> verifyOtp(String email, String otpCode) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email.trim(),
        token: otpCode.trim(),
        type: OtpType.email,
      );
    } on AuthException {
      throw Exception('Invalid or expired code. Please try again.');
    }
  }

  // ── Forgot password: Step 3 — set new password ────────────────────────────
  Future<void> resetPassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
