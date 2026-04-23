import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
          Text('All working days in the month',
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
          label: 'Present',
          value: '${_viewModel.totalPresent + _viewModel.totalLate}',
          icon: Icons.check_circle_rounded,
          color: AppTheme.success,
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _SummaryCard(
          label: 'On Leave',
          value: '${_viewModel.totalOnLeave}',
          icon: Icons.beach_access_rounded,
          color: const Color(0xFF8B5CF6), // purple
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _SummaryCard(
          label: 'Absent',
          value: '${_viewModel.totalAbsent}',
          icon: Icons.cancel_rounded,
          color: AppTheme.danger,
        )),
      ],
    );
  }

  // ── Records list ──────────────────────────────────────────────────────────

  Widget _buildRecordsList() {
    if (_viewModel.dayRecords.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_viewModel.totalWorkingDays} working day${_viewModel.totalWorkingDays == 1 ? '' : 's'}',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted),
        ),
        const SizedBox(height: 10),
        ...(_viewModel.dayRecords.map((r) => _DayCard(record: r))),
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
            const Text('No working days',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 6),
            Text(
              'No working days found for ${DateFormat('MMMM yyyy').format(_viewModel.selectedMonth)}',
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
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

// ── Day card (renders all 5 statuses) ─────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final DayRecord record;
  const _DayCard({required this.record});

  // Status → visual config
  ({Color color, String label, IconData icon}) _statusConfig() {
    switch (record.status) {
      case DayStatus.present:
        return (
          color: AppTheme.success,
          label: 'Present',
          icon: Icons.check_circle_rounded,
        );
      case DayStatus.late:
        return (
          color: AppTheme.warning,
          label: 'Late',
          icon: Icons.schedule_rounded,
        );
      case DayStatus.onLeave:
        return (
          color: const Color(0xFF8B5CF6),
          label: 'On Leave',
          icon: Icons.beach_access_rounded,
        );
      case DayStatus.absent:
        return (
          color: AppTheme.danger,
          label: 'Absent',
          icon: Icons.cancel_rounded,
        );
      case DayStatus.upcoming:
        return (
          color: AppTheme.textMuted,
          label: 'Upcoming',
          icon: Icons.event_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig();
    final date = record.date;
    final dayName = DateFormat('EEE').format(date); // Mon
    final dayNum = DateFormat('dd').format(date);   // 12
    final monthYear = DateFormat('MMM yyyy').format(date);

    final isMuted = record.status == DayStatus.upcoming;
    final isAbsent = record.status == DayStatus.absent;
    final isLeave = record.status == DayStatus.onLeave;
    final att = record.attendance;
    final hasAttendance = att != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isAbsent
            ? Border.all(color: AppTheme.danger.withValues(alpha: 0.25))
            : null,
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
            // ── Date block ──
            Container(
              width: 50,
              height: 56,
              decoration: BoxDecoration(
                gradient: isMuted
                    ? null
                    : LinearGradient(
                        colors: [
                          cfg.color,
                          cfg.color.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isMuted ? const Color(0xFFF3F4F6) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayName,
                      style: TextStyle(
                          color: isMuted ? AppTheme.textMuted : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  Text(dayNum,
                      style: TextStyle(
                          color: isMuted ? AppTheme.textMuted : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // ── Main info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(monthYear,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isMuted
                                  ? AppTheme.textMuted
                                  : AppTheme.textDark)),
                      const SizedBox(width: 8),
                      _Badge(label: cfg.label, color: cfg.color, icon: cfg.icon),
                      if (hasAttendance && att.type == 'wfh') ...[
                        const SizedBox(width: 4),
                        _Badge(
                          label: 'WFH',
                          color: AppTheme.secondary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildSubRow(),
                ],
              ),
            ),

            // ── Right-side info (duration or half day) ──
            if (hasAttendance && att.duration != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Duration',
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textMuted)),
                  Text(att.durationText,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                ],
              )
            else if (isLeave && record.isHalfDay)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Half day',
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textMuted)),
                  Text(record.halfDayPeriod ?? '-',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B5CF6))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubRow() {
    final att = record.attendance;
    switch (record.status) {
      case DayStatus.present:
      case DayStatus.late:
        return Row(
          children: [
            _TimeChip(
              icon: Icons.login_rounded,
              label: att?.clockIn != null
                  ? DateFormat('hh:mm a').format(att!.clockIn!)
                  : '-',
              color: AppTheme.success,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                size: 12, color: AppTheme.textMuted),
            const SizedBox(width: 8),
            _TimeChip(
              icon: Icons.logout_rounded,
              label: att?.clockOut != null
                  ? DateFormat('hh:mm a').format(att!.clockOut!)
                  : 'Working...',
              color: att?.clockOut != null
                  ? AppTheme.danger
                  : AppTheme.warning,
            ),
          ],
        );

      case DayStatus.onLeave:
        return Text(
          record.leaveTypeName ?? 'Leave',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B5CF6)),
        );

      case DayStatus.absent:
        return const Text(
          'No clock-in recorded',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.danger),
        );

      case DayStatus.upcoming:
        return const Text(
          'Scheduled working day',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted),
        );
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
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
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark)),
      ],
    );
  }
}
