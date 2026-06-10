import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart';
import '../../viewmodels/claim_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import '../widgets/claims/header_stat.dart';
import '../widgets/claims/claim_card.dart';
import '../widgets/claims/submit_claim_sheet.dart';

class ClaimsScreen extends StatefulWidget {
  final UserModel user;
  final CompanyModel company;

  const ClaimsScreen({super.key, required this.user, required this.company});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  late ClaimViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ClaimViewModel(user: widget.user, company: widget.company);
    _viewModel.addListener(_onChanged);
    _viewModel.loadData();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_viewModel.successMessage != null) {
      _snack(_viewModel.successMessage!, isError: false);
      _viewModel.clearMessages();
    } else if (_viewModel.errorMessage != null) {
      _snack(_viewModel.errorMessage!, isError: true);
      _viewModel.clearMessages();
    }
    setState(() {});
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitSheet,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Submit Claim',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Claims',
              style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(DateFormat('MMMM yyyy').format(DateTime.now()),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              ClaimHeaderStat(
                  label: 'Pending', value: '${_viewModel.pendingCount}', color: Colors.amber),
              const SizedBox(width: 16),
              ClaimHeaderStat(
                  label: 'Approved', value: '${_viewModel.approvedCount}', color: Colors.greenAccent),
              const SizedBox(width: 16),
              ClaimHeaderStat(
                  label: 'Total (RM)',
                  value: _viewModel.totalApproved.toStringAsFixed(2),
                  color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_viewModel.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 64, color: AppTheme.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No claims yet',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
            const SizedBox(height: 6),
            const Text('Tap "Submit Claim" to get started',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return HapticRefreshIndicator(
      onRefresh: _viewModel.loadData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: _viewModel.history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => ClaimCard(claim: _viewModel.history[i]),
      ),
    );
  }

  // ── Submit Sheet ───────────────────────────────────────────────────────────
  void _showSubmitSheet() {
    final nav = Navigator.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SubmitClaimSheet(
        userId:    widget.user.id,
        userGrade: widget.user.grade,
        onSubmit: (args) async {
          final success = await _viewModel.submitClaim(
            claimType:    args['claimType'],
            title:        args['title'],
            description:  args['description'],
            claimDate:    args['claimDate'],
            amount:       args['amount'],
            suggestedAmount:     args['suggestedAmount'],
            receiptUrl:          args['receiptUrl'],
            transportMode:       args['transportMode'],
            distanceKm:          args['distanceKm'],
            tollAmount:          args['tollAmount'],
            parkingAmount:       args['parkingAmount'],
            destinationType:     args['destinationType'],
            distanceFromOfficeKm: args['distanceFromOfficeKm'],
            numberOfNights:          args['numberOfNights'],
            hasAccommodationReceipt: args['hasAccommodationReceipt'],
            numberOfDays:    args['numberOfDays'],
            isOvernightStay: args['isOvernightStay'],
            returnDateTime:  args['returnDateTime'],
            overseasTransportCost: args['overseasTransportCost'],
            overseasPhoneCost:     args['overseasPhoneCost'],
            overseasLaundryCost:   args['overseasLaundryCost'],
            overseasOtherCost:     args['overseasOtherCost'],
          );
          if (!success) {
            throw Exception(_viewModel.errorMessage ?? 'Failed to submit.');
          }
          nav.pop();
        },
      ),
    );
  }
}

