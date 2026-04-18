import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart';
import '../../models/leave_policy_model.dart';
import '../../models/leave_balance_model.dart';
import '../../models/leave_request_model.dart';
import '../../viewmodels/leave_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../services/leave_service.dart';

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

    return RefreshIndicator(
      color: AppTheme.primary,
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
          ..._viewModel.balances.map((b) => _BalanceCard(balance: b)),
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

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _viewModel.loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _viewModel.history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _HistoryCard(
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
      builder: (_) => _ApplyLeaveSheet(
        policies: _viewModel.policies,
        balances: _viewModel.balances,
        userId: widget.user.id,
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

// ── Balance Card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final LeaveBalanceModel balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final used = balance.usedDays;
    final pending = balance.pendingDays;
    final remaining = balance.remainingDays;
    final total = balance.totalDays.toDouble();
    final progress = total > 0 ? (used + pending) / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                balance.leavePolicyName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${remaining % 1 == 0 ? remaining.toInt() : remaining} / ${balance.totalDays} days',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? AppTheme.danger : AppTheme.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BalanceStat(label: 'Used', value: used, color: AppTheme.danger),
              const SizedBox(width: 16),
              _BalanceStat(
                label: 'Pending',
                value: pending,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 16),
              _BalanceStat(
                label: 'Remaining',
                value: remaining,
                color: AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _BalanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final display = value % 1 == 0
        ? value.toInt().toString()
        : value.toString();
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$display $label',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final LeaveRequestModel request;
  final void Function(String) onCancel;
  const _HistoryCard({required this.request, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (request.status) {
      'approved' => AppTheme.success,
      'rejected' => AppTheme.danger,
      'cancelled' => AppTheme.textMuted,
      _ => AppTheme.warning,
    };
    final statusLabel =
        request.status[0].toUpperCase() + request.status.substring(1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request.leavePolicyName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                request.startDate == request.endDate
                    ? DateFormat('d MMM yyyy').format(request.startDate)
                    : '${DateFormat('d MMM').format(request.startDate)} – ${DateFormat('d MMM yyyy').format(request.endDate)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                request.isHalfDay
                    ? '½ day (${request.halfDayPeriod})'
                    : '${request.totalDays % 1 == 0 ? request.totalDays.toInt() : request.totalDays} day(s)',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          if (request.reason != null && request.reason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              request.reason!,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (request.hrRemarks != null && request.hrRemarks!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.comment_rounded, size: 12, color: statusColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'HR: ${request.hrRemarks}',
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (request.status == 'pending') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => onCancel(request.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel Request',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Apply Leave Sheet ─────────────────────────────────────────────────────────

class _ApplyLeaveSheet extends StatefulWidget {
  final List<LeavePolicyModel> policies;
  final List<LeaveBalanceModel> balances;
  final String userId;
  final Future<void> Function({
    required String leavePolicyId,
    required DateTime startDate,
    required DateTime endDate,
    required bool isHalfDay,
    String? halfDayPeriod,
    String? reason,
    String? attachmentUrl,
  })
  onSubmit;

  const _ApplyLeaveSheet({
    required this.policies,
    required this.balances,
    required this.userId,
    required this.onSubmit,
  });

  @override
  State<_ApplyLeaveSheet> createState() => _ApplyLeaveSheetState();
}

class _ApplyLeaveSheetState extends State<_ApplyLeaveSheet> {
  LeavePolicyModel? _selectedPolicy;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isHalfDay = false;
  String _halfDayPeriod = 'morning';
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  PlatformFile? _pickedFile;

  // Inline validation errors
  String? _policyError;
  String? _dateError;
  String? _documentError;
  String? _submitError;

  double get _calculatedDays {
    if (_startDate == null) return 0;
    // If end not picked yet, treat as single day
    final end = _endDate ?? _startDate!;
    return LeaveService.calculateDays(_startDate!, end, _isHalfDay);
  }

  LeaveBalanceModel? get _selectedBalance {
    if (_selectedPolicy == null) return null;
    try {
      return widget.balances.firstWhere(
        (b) => b.leavePolicyId == _selectedPolicy!.id,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File too large. Maximum size is 5 MB.')),
          );
        }
        return;
      }
      setState(() => _pickedFile = file);
    }
  }

  Future<void> _submit() async {
    // Validate inline
    setState(() {
      _policyError = _selectedPolicy == null ? 'Please select a leave type' : null;
      _dateError = _startDate == null ? 'Please select a date' : null;
      _documentError = (_selectedPolicy?.requiresDocument == true && _pickedFile == null)
          ? 'A supporting document is required for this leave type'
          : null;
      _submitError = null;
    });

    if (_policyError != null || _dateError != null || _documentError != null) return;

    setState(() => _isSubmitting = true);

    // Upload attachment if picked
    String? attachmentUrl;
    if (_pickedFile != null && _pickedFile!.bytes != null) {
      try {
        attachmentUrl = await LeaveService().uploadAttachment(
          employeeId: widget.userId,
          bytes: _pickedFile!.bytes!,
          fileName: _pickedFile!.name,
        );
      } catch (e) {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Upload failed: ${e.toString().replaceFirst('Exception: ', '')}'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }
    }

    try {
      await widget.onSubmit(
        leavePolicyId: _selectedPolicy!.id,
        startDate: _startDate!,
        endDate: _endDate ?? _startDate!,
        isHalfDay: _isHalfDay,
        halfDayPeriod: _isHalfDay ? _halfDayPeriod : null,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        attachmentUrl: attachmentUrl,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[Submit] caught error: $msg');
      if (mounted) setState(() => _submitError = msg);
    }
    // Sheet may have been closed on success — guard before setState
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Apply Leave',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 20),

              // Leave type
              const Text(
                'Leave Type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LeavePolicyModel>(
                    value: _selectedPolicy,
                    isExpanded: true,
                    hint: const Text(
                      'Select leave type',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    items: widget.policies.map((p) {
                      final balance = widget.balances
                          .where((b) => b.leavePolicyId == p.id)
                          .firstOrNull;
                      return DropdownMenuItem(
                        value: p,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p.name),
                            if (balance != null)
                              Text(
                                '${balance.remainingDays % 1 == 0 ? balance.remainingDays.toInt() : balance.remainingDays} days left',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() {
                      _selectedPolicy = val;
                      _policyError = null;
                      if (val != null && !val.allowHalfDay) {
                        _isHalfDay = false;
                      }
                    }),
                  ),
                ),
              ),

              // Policy inline error
              if (_policyError != null) ...[
                const SizedBox(height: 6),
                _InlineError(message: _policyError!),
              ],

              // Balance info
              if (_selectedBalance != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remaining: ${_selectedBalance!.remainingDays % 1 == 0 ? _selectedBalance!.remainingDays.toInt() : _selectedBalance!.remainingDays} / ${_selectedBalance!.totalDays} days',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Half day toggle — always shown when a policy is selected
              if (_selectedPolicy != null) ...[
                Opacity(
                  opacity: _selectedPolicy!.allowHalfDay ? 1.0 : 0.4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Half Day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          if (!_selectedPolicy!.allowHalfDay)
                            const Text(
                              'Not available for this leave type',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                        ],
                      ),
                      Switch(
                        value: _isHalfDay,
                        activeColor: AppTheme.primary,
                        onChanged: _selectedPolicy!.allowHalfDay
                            ? (val) => setState(() {
                                  _isHalfDay = val;
                                  if (val && _startDate != null) {
                                    _endDate = _startDate;
                                  }
                                  if (!val) _endDate = null;
                                })
                            : null,
                      ),
                    ],
                  ),
                ),
                if (_isHalfDay) ...[
                  Row(
                    children: [
                      _HalfDayChip(
                        label: 'Morning',
                        isSelected: _halfDayPeriod == 'morning',
                        onTap: () => setState(() => _halfDayPeriod = 'morning'),
                      ),
                      const SizedBox(width: 10),
                      _HalfDayChip(
                        label: 'Afternoon',
                        isSelected: _halfDayPeriod == 'afternoon',
                        onTap: () =>
                            setState(() => _halfDayPeriod = 'afternoon'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],

              const SizedBox(height: 4),

              // ── Inline range calendar ──────────────────────────────────────
              const Text(
                'Select Date(s)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),

              // Selected date summary row
              _DateSummaryRow(
                startDate: _startDate,
                endDate: _endDate,
                isHalfDay: _isHalfDay,
                onClear: () => setState(() {
                  _startDate = null;
                  _endDate = null;
                }),
              ),
              const SizedBox(height: 8),

              // Calendar
              _RangeDatePicker(
                startDate: _startDate,
                endDate: _endDate,
                isHalfDay: _isHalfDay,
                onChanged: (start, end) => setState(() {
                  _startDate = start;
                  _endDate = end;
                  _dateError = null;
                }),
              ),

              // Date inline error
              if (_dateError != null) ...[
                const SizedBox(height: 6),
                _InlineError(message: _dateError!),
              ],

              // Days summary
              if (_startDate != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total: $_calculatedDays working day(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Document Upload ────────────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Supporting Document',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_selectedPolicy?.requiresDocument == true)
                    const Text(
                      '(required)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const Text(
                      '(optional)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _pickedFile != null
                          ? AppTheme.primary
                          : const Color(0xFFE5E7EB),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: _pickedFile != null
                        ? AppTheme.primary.withValues(alpha: 0.04)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _pickedFile != null
                              ? Icons.insert_drive_file_rounded
                              : Icons.upload_file_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pickedFile != null
                                  ? _pickedFile!.name
                                  : 'Tap to upload',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _pickedFile != null
                                    ? AppTheme.textDark
                                    : AppTheme.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _pickedFile != null
                                  ? '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB'
                                  : 'PDF, JPG or PNG • max 5 MB',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_pickedFile != null)
                        GestureDetector(
                          onTap: () => setState(() {
                            _pickedFile = null;
                            _documentError = null;
                          }),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Document inline error
              if (_documentError != null) ...[
                const SizedBox(height: 6),
                _InlineError(message: _documentError!),
              ],

              const SizedBox(height: 16),

              // Reason
              const Text(
                'Reason (optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason for leave...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit-level error (e.g. Supabase error)
              if (_submitError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _submitError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.danger,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date Summary Row ──────────────────────────────────────────────────────────

class _DateSummaryRow extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isHalfDay;
  final VoidCallback onClear;

  const _DateSummaryRow({
    required this.startDate,
    required this.endDate,
    required this.isHalfDay,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (startDate == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Text(
          'Tap a date to start. Tap another to set the end date.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      );
    }

    final fmt = DateFormat('d MMM yyyy');
    String label;

    if (isHalfDay) {
      label = fmt.format(startDate!);
    } else if (endDate == null) {
      label = '${fmt.format(startDate!)}  →  tap to set end';
    } else {
      final isSame = startDate!.year == endDate!.year &&
          startDate!.month == endDate!.month &&
          startDate!.day == endDate!.day;
      label = isSame
          ? fmt.format(startDate!)
          : '${fmt.format(startDate!)}  –  ${fmt.format(endDate!)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Range Date Picker ─────────────────────────────────────────────────────────

class _RangeDatePicker extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isHalfDay;
  final void Function(DateTime? start, DateTime? end) onChanged;

  const _RangeDatePicker({
    required this.startDate,
    required this.endDate,
    required this.isHalfDay,
    required this.onChanged,
  });

  @override
  State<_RangeDatePicker> createState() => _RangeDatePickerState();
}

class _RangeDatePickerState extends State<_RangeDatePicker> {
  late DateTime _focusedMonth;

  static const _weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _rangeColor = Color(0xFFCCF3F8); // light teal tint

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onDayTap(DateTime tapped) {
    final start = widget.startDate;
    final end = widget.endDate;

    // Half day — always single day
    if (widget.isHalfDay) {
      widget.onChanged(tapped, tapped);
      return;
    }

    // No start yet, or both already set → start fresh
    if (start == null || (start != null && end != null)) {
      widget.onChanged(tapped, null);
      return;
    }

    // Have start, no end yet
    if (_sameDay(tapped, start)) {
      // Tapped same day → confirm single-day selection
      widget.onChanged(start, start);
    } else if (tapped.isBefore(start)) {
      // Tapped before start → swap
      widget.onChanged(tapped, start);
    } else {
      // Tapped after start → set end
      widget.onChanged(start, tapped);
    }
  }

  Widget _buildDayCell(DateTime day) {
    final start = widget.startDate;
    final end = widget.endDate;

    final isStart = start != null && _sameDay(day, start);
    final isEnd = end != null && _sameDay(day, end);
    final isSingleDay = isStart && isEnd;

    final hasRange = start != null && end != null && !_sameDay(start, end);
    final inRange = hasRange &&
        day.isAfter(start!) &&
        day.isBefore(end!);

    final isToday = _sameDay(day, DateTime.now());

    // Disable past (>30 days ago) and far future (>1 year)
    final isDisabled = day.isBefore(
          DateTime.now().subtract(const Duration(days: 30)),
        ) ||
        day.isAfter(DateTime.now().add(const Duration(days: 365)));

    // Range background: left half and right half independently
    final bool leftBg = inRange || (isEnd && hasRange);
    final bool rightBg = inRange || (isStart && hasRange);

    return GestureDetector(
      onTap: isDisabled ? null : () => _onDayTap(day),
      child: SizedBox(
        height: 40,
        child: Stack(
          children: [
            // ── Range highlight background ──
            Row(
              children: [
                Expanded(
                  child: Container(
                    color: leftBg ? _rangeColor : Colors.transparent,
                  ),
                ),
                Expanded(
                  child: Container(
                    color: rightBg ? _rangeColor : Colors.transparent,
                  ),
                ),
              ],
            ),

            // ── Day circle ──
            Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isStart || isEnd) && !isSingleDay
                      ? AppTheme.primary
                      : isSingleDay
                          ? AppTheme.primary
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isStart && !isEnd
                      ? Border.all(color: AppTheme.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: (isStart || isEnd)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: (isStart || isEnd)
                          ? Colors.white
                          : isDisabled
                              ? const Color(0xFFD1D5DB)
                              : isToday
                                  ? AppTheme.primary
                                  : AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // weekday: Mon=1..Sun=7 → convert to Sun=0..Sat=6
    final startOffset = firstOfMonth.weekday % 7;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: [
          // ── Month navigation ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                color: AppTheme.textDark,
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  );
                }),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                color: AppTheme.textDark,
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  );
                }),
              ),
            ],
          ),

          // ── Week day labels ──
          Row(
            children: _weekLabels
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 4),

          // ── Days grid ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, index) {
              if (index < startOffset) return const SizedBox();
              final day = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                index - startOffset + 1,
              );
              return _buildDayCell(day);
            },
          ),
        ],
      ),
    );
  }
}

// ── Half Day Chip ─────────────────────────────────────────────────────────────

// ── Inline Error ──────────────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 13, color: AppTheme.danger),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Half Day Chip ─────────────────────────────────────────────────────────────

class _HalfDayChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _HalfDayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
