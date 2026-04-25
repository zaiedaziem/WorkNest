import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/forgot_password_viewmodel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _viewModel = ForgotPasswordViewModel();

  // Step 1
  final _companyCodeController = TextEditingController();
  final _employeeIdController = TextEditingController();

  // Step 2
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // Step 3
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _companyCodeController.dispose();
    _employeeIdController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _otpValue =>
      _otpControllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: _viewModel.step == ForgotPasswordStep.done
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: AppTheme.textDark, size: 20),
                onPressed: () {
                  if (_viewModel.step == ForgotPasswordStep.requestOtp) {
                    Navigator.pop(context);
                  } else {
                    _viewModel.goBack();
                  }
                },
              ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0.05, 0), end: Offset.zero)
                    .animate(animation),
                child: child,
              ),
            ),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_viewModel.step) {
      case ForgotPasswordStep.requestOtp:
        return _buildStep1(key: const ValueKey('step1'));
      case ForgotPasswordStep.verifyOtp:
        return _buildStep2(key: const ValueKey('step2'));
      case ForgotPasswordStep.resetPassword:
        return _buildStep3(key: const ValueKey('step3'));
      case ForgotPasswordStep.done:
        return _buildDone(key: const ValueKey('done'));
    }
  }

  // ── Step 1: Enter Company Code + Employee ID ─────────────────────────────

  Widget _buildStep1({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _StepHeader(
          icon: Icons.lock_reset_rounded,
          title: 'Forgot Password?',
          subtitle:
              'Enter your Company Code and Employee ID. We\'ll send a 6-digit reset code to the email linked to your account.',
        ),
        const SizedBox(height: 32),

        if (_viewModel.errorMessage != null) ...[
          _ErrorBanner(message: _viewModel.errorMessage!),
          const SizedBox(height: 16),
        ],

        const _FieldLabel('Company Code'),
        const SizedBox(height: 8),
        TextField(
          controller: _companyCodeController,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            hintText: 'e.g. acme',
            prefixIcon:
                Icon(Icons.business_rounded, color: AppTheme.textMuted),
          ),
        ),

        const SizedBox(height: 16),

        const _FieldLabel('Employee ID'),
        const SizedBox(height: 8),
        TextField(
          controller: _employeeIdController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitStep1(),
          decoration: const InputDecoration(
            hintText: 'e.g. EMP001',
            prefixIcon: Icon(Icons.badge_rounded, color: AppTheme.textMuted),
          ),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _viewModel.isLoading ? null : _submitStep1,
            child: _viewModel.isLoading
                ? const _LoadingIndicator()
                : const Text('Send Reset Code'),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  void _submitStep1() {
    final companyCode = _companyCodeController.text.trim();
    final employeeId = _employeeIdController.text.trim();
    if (companyCode.isEmpty || employeeId.isEmpty) return;
    _viewModel.requestOtp(
      companyCode: companyCode,
      employeeId: employeeId,
    );
  }

  // ── Step 2: Enter 6-digit OTP ────────────────────────────────────────────

  Widget _buildStep2({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _StepHeader(
          icon: Icons.mark_email_read_rounded,
          title: 'Check Your Email',
          subtitle:
              'We\'ve sent a 6-digit code to ${_viewModel.maskedEmail}. Enter it below.',
        ),
        const SizedBox(height: 32),

        if (_viewModel.errorMessage != null) ...[
          _ErrorBanner(message: _viewModel.errorMessage!),
          const SizedBox(height: 16),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _buildOtpBox(i)),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _viewModel.isLoading || _otpValue.length < 6
                ? null
                : () => _viewModel.verifyOtp(_otpValue),
            child: _viewModel.isLoading
                ? const _LoadingIndicator()
                : const Text('Verify Code'),
          ),
        ),

        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: _viewModel.isLoading
                ? null
                : () {
                    for (final c in _otpControllers) {
                      c.clear();
                    }
                    _viewModel.resendOtp();
                  },
            child: const Text('Resend Code',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textDark),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  // ── Step 3: Set new password ─────────────────────────────────────────────

  Widget _buildStep3({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _StepHeader(
          icon: Icons.lock_rounded,
          title: 'Set New Password',
          subtitle: 'Choose a strong password. It must be at least 6 characters.',
        ),
        const SizedBox(height: 32),

        if (_viewModel.errorMessage != null) ...[
          _ErrorBanner(message: _viewModel.errorMessage!),
          const SizedBox(height: 16),
        ],

        const _FieldLabel('New Password'),
        const SizedBox(height: 8),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'Enter new password',
            prefixIcon:
                const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppTheme.textMuted,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),

        const SizedBox(height: 16),

        const _FieldLabel('Confirm Password'),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitStep3(),
          decoration: InputDecoration(
            hintText: 'Repeat new password',
            prefixIcon:
                const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppTheme.textMuted,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _viewModel.isLoading ? null : _submitStep3,
            child: _viewModel.isLoading
                ? const _LoadingIndicator()
                : const Text('Reset Password'),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  void _submitStep3() {
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPass.isEmpty || confirm.isEmpty) return;

    if (newPass != confirm) {
      _viewModel.clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match.'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password must be at least 6 characters.'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    _viewModel.resetPassword(newPass);
  }

  // ── Done ────────────────────────────────────────────────────────────────

  Widget _buildDone({Key? key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'Password Reset!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your password has been updated.\nYou can now log in with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StepHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 20),
        Text(title,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textMuted, height: 1.5)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.textDark));
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.danger.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style:
                    const TextStyle(color: AppTheme.danger, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );
  }
}
