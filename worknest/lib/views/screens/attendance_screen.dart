import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/attendance_viewmodel.dart';

class AttendanceScreen extends StatefulWidget {
  final UserModel user;

  const AttendanceScreen({super.key, required this.user});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late AttendanceViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AttendanceViewModel(employeeId: widget.user.id);
    _viewModel.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _viewModel.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary))
                  : _viewModel.errorMessage != null
                      ? _buildError()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          Text('Your work attendance history',
              style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted.withValues(alpha: 0.8))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Main content ──────────────────────────────────────────────────────────

  Widget _buildContent() {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => _viewModel.loadMonth(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          _buildMonthSelector(),
          const SizedBox(height: 16),
          _buildSummaryCards(),
          const SizedBox(height: 20),
          _buildRecordsList(),
        ],
      ),
    );
  }

  // ── Month selector ────────────────────────────────────────────────────────

  Widget _buildMonthSelector() {
    final month = DateFormat('MMMM yyyy').format(_viewModel.selectedMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _viewModel.previousMonth,
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        Text(month,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark)),
        IconButton(
          onPressed:
              _viewModel.canGoNext ? _viewModel.nextMonth : null,
          icon: const Icon(Icons.chevron_right_rounded, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: _viewModel.canGoNext
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            foregroundColor: _viewModel.canGoNext
                ? AppTheme.textDark
                : AppTheme.textMuted,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // ── Summary cards ─────────────────────────────────────────────────────────

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
            child: _SummaryCard(
          label: 'Total Days',
          value: '${_viewModel.totalDays}',
          icon: Icons.calendar_month_rounded,
          color: AppTheme.primary,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _SummaryCard(
          label: 'Present',
          value: '${_viewModel.totalPresent}',
          icon: Icons.check_circle_rounded,
          color: AppTheme.success,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _SummaryCard(
          label: 'Late',
          value: '${_viewModel.totalLate}',
          icon: Icons.schedule_rounded,
          color: AppTheme.warning,
        )),
      ],
    );
  }

  // ── Records list ──────────────────────────────────────────────────────────

  Widget _buildRecordsList() {
    if (_viewModel.records.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_viewModel.records.length} record${_viewModel.records.length == 1 ? '' : 's'}',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted),
        ),
        const SizedBox(height: 10),
        ...(_viewModel.records.map((r) => _AttendanceCard(record: r))),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  color: AppTheme.primary, size: 34),
            ),
            const SizedBox(height: 16),
            const Text('No attendance records',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 6),
            Text(
              'No records found for ${DateFormat('MMMM yyyy').format(_viewModel.selectedMonth)}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 44),
            const SizedBox(height: 12),
            Text(_viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _viewModel.loadMonth,
                child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── Summary card widget ───────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

// ── Attendance record card ────────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  final AttendanceModel record;

  const _AttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = record.date;
    final dayName = DateFormat('EEE').format(date);   // Mon
    final dayNum = DateFormat('dd').format(date);     // 12
    final monthYear = DateFormat('MMM yyyy').format(date); // Apr 2026

    final isLate = record.status == 'late';
    final isWfh = record.type == 'wfh';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Date block
            Container(
              width: 50,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  Text(dayNum,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(monthYear,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark)),
                      const SizedBox(width: 8),
                      // Status badge
                      _Badge(
                        label: isLate ? 'Late' : 'Present',
                        color: isLate ? AppTheme.warning : AppTheme.success,
                      ),
                      const SizedBox(width: 4),
                      // Type badge
                      _Badge(
                        label: isWfh ? 'WFH' : 'Office',
                        color: isWfh ? AppTheme.secondary : AppTheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _TimeChip(
                        icon: Icons.login_rounded,
                        label: record.clockIn != null
                            ? DateFormat('hh:mm a').format(record.clockIn!)
                            : '-',
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      _TimeChip(
                        icon: Icons.logout_rounded,
                        label: record.clockOut != null
                            ? DateFormat('hh:mm a').format(record.clockOut!)
                            : 'Working...',
                        color: record.clockOut != null
                            ? AppTheme.danger
                            : AppTheme.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Duration
            if (record.duration != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Duration',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted)),
                  Text(record.durationText,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TimeChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark)),
      ],
    );
  }
}
