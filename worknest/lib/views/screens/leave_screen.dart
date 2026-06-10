import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart';
import '../../viewmodels/leave_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import '../widgets/leave/balance_card.dart';
import '../widgets/leave/history_card.dart';
import '../widgets/leave/apply_leave_sheet.dart';

class LeaveScreen extends StatefulWidget {
  final UserModel user;
  final CompanyModel company;

  const LeaveScreen({super.key, required this.user, required this.company});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen>
    with SingleTickerProviderStateMixin {
  late LeaveViewModel _viewModel;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel = LeaveViewModel(user: widget.user, company: widget.company);
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadData();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    if (_viewModel.successMessage != null) {
      _showSnackbar(_viewModel.successMessage!, isError: false);
      _viewModel.clearMessages();
    } else if (_viewModel.errorMessage != null) {
      _showSnackbar(_viewModel.errorMessage!, isError: true);
      _viewModel.clearMessages();
    }
    setState(() {});
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
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
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildBalanceTab(), _buildHistoryTab()],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _viewModel.policies.isEmpty ? null : _showApplyLeaveSheet,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Apply Leave',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Leave',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            DateFormat('MMMM yyyy').format(DateTime.now()),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textMuted,
        indicatorColor: AppTheme.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'Balance'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  // ── Balance Tab ────────────────────────────────────────────────────────────

  Widget _buildBalanceTab() {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_viewModel.balances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.beach_access_rounded,
              size: 60,
              color: AppTheme.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No leave balance assigned yet.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please contact HR to set up your leave balance.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return HapticRefreshIndicator(
      onRefresh: _viewModel.loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Leave Entitlement',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const Text(
            'Current year balance',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 14),
          ..._viewModel.balances.map((b) => BalanceCard(balance: b)),
        ],
      ),
    );
  }

  // ── History Tab ────────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_viewModel.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 60,
              color: AppTheme.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No leave requests yet.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return HapticRefreshIndicator(
      onRefresh: _viewModel.loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _viewModel.history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => HistoryCard(
          request: _viewModel.history[i],
          onCancel: (id) => _confirmCancel(id),
        ),
      ),
    );
  }

  // ── Apply Leave Bottom Sheet ───────────────────────────────────────────────

  void _showApplyLeaveSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ApplyLeaveSheet(
        policies: _viewModel.policies,
        balances: _viewModel.balances,
        userId: widget.user.id,
        userGender: widget.user.gender,
        onSubmit:
            ({
              required leavePolicyId,
              required startDate,
              required endDate,
              required isHalfDay,
              halfDayPeriod,
              reason,
              attachmentUrl,
            }) async {
              // Submit FIRST — only close the sheet if it succeeds.
              // On failure the sheet stays open so the error snackbar is visible.
              final success = await _viewModel.submitRequest(
                leavePolicyId: leavePolicyId,
                startDate: startDate,
                endDate: endDate,
                isHalfDay: isHalfDay,
                halfDayPeriod: halfDayPeriod,
                reason: reason,
                attachmentUrl: attachmentUrl,
              );
              if (success) {
                if (context.mounted) Navigator.pop(context);
              } else {
                // Throw so _submit() can show it as a dialog
                throw Exception(_viewModel.errorMessage ?? 'Failed to submit. Please try again.');
              }
            },
      ),
    );
  }

  void _confirmCancel(String requestId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Cancel Request',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to cancel this leave request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _viewModel.cancelRequest(requestId);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }
}

