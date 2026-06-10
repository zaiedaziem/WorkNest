import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/attendance_viewmodel.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import '../widgets/attendance/hero_card.dart';
import '../widgets/attendance/on_time_card.dart';
import '../widgets/attendance/day_card.dart';
import '../widgets/attendance/attendance_filter_chip.dart';
import '../widgets/attendance/week_group.dart';

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
    return HapticRefreshIndicator(
      onRefresh: () => _viewModel.loadMonth(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          _buildMonthSelector(),
          const SizedBox(height: 16),
          _buildSummaryCards(),
          const SizedBox(height: 16),
          _buildFilterChips(),
          const SizedBox(height: 16),
          _buildRecordsList(),
        ],
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    final chips = <({DayFilter filter, String label, int count, Color color})>[
      (
        filter: DayFilter.all,
        label: 'All',
        count: _viewModel.totalWorkingDays,
        color: AppTheme.primary,
      ),
      (
        filter: DayFilter.present,
        label: 'Present',
        count: _viewModel.totalPresent,
        color: AppTheme.success,
      ),
      (
        filter: DayFilter.late,
        label: 'Late',
        count: _viewModel.totalLate,
        color: AppTheme.warning,
      ),
      (
        filter: DayFilter.onLeave,
        label: 'Leave',
        count: _viewModel.totalOnLeave,
        color: const Color(0xFF8B5CF6),
      ),
      (
        filter: DayFilter.absent,
        label: 'Absent',
        count: _viewModel.totalAbsent,
        color: AppTheme.danger,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in chips)
          AttendanceFilterChip(
            label: c.label,
            count: c.count,
            color: c.color,
            isSelected: _viewModel.filter == c.filter,
            onTap: () => _viewModel.setFilter(c.filter),
          ),
      ],
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

  // ── Summary cards (hero row: hours worked + on-time rate) ─────────────────

  Widget _buildSummaryCards() {
    final rate = _viewModel.onTimeRate;
    return Row(
      children: [
        Expanded(
          child: AttendanceHeroCard(
            icon: Icons.schedule_rounded,
            value: _viewModel.totalHoursWorkedText,
            label: 'Hours Worked',
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OnTimeCard(
            rate: rate,
            valueText: _viewModel.onTimeRateText,
          ),
        ),
      ],
    );
  }

  // ── Records list ──────────────────────────────────────────────────────────

  Widget _buildRecordsList() {
    final filtered = _viewModel.filteredDayRecords;

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    final groups = _groupByWeek(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${filtered.length} day${filtered.length == 1 ? '' : 's'}'
          '${_viewModel.filter != DayFilter.all ? ' · filtered' : ''}',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted),
        ),
        const SizedBox(height: 10),
        for (final g in groups) ...[
          WeekHeader(group: g),
          const SizedBox(height: 8),
          ...g.days.map((r) => DayCard(record: r)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// Group day records by ISO week (Mon–Sun). Weeks and days within each week
  /// are sorted chronologically (Day 1 → end of month).
  List<WeekGroup> _groupByWeek(List<DayRecord> records) {
    final byMonday = <DateTime, List<DayRecord>>{};

    for (final r in records) {
      // Monday of that week
      final monday = r.date.subtract(Duration(days: r.date.weekday - 1));
      final mondayOnly = DateTime(monday.year, monday.month, monday.day);
      byMonday.putIfAbsent(mondayOnly, () => []).add(r);
    }

    // Sort weeks oldest first (by Monday asc)
    final mondays = byMonday.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return mondays.map((m) {
      final days = byMonday[m]!;
      // Ensure days within a week are oldest first
      days.sort((a, b) => a.date.compareTo(b.date));

      int present = 0;
      int late = 0;
      int onLeave = 0;
      int absent = 0;
      Duration worked = Duration.zero;

      for (final d in days) {
        switch (d.status) {
          case DayStatus.present:
            present++;
            break;
          case DayStatus.late:
            late++;
            break;
          case DayStatus.onLeave:
            onLeave++;
            break;
          case DayStatus.absent:
            absent++;
            break;
          case DayStatus.upcoming:
          case DayStatus.weekend:
            break;
        }
        final dur = d.attendance?.duration;
        if (dur != null) worked += dur;
      }

      return WeekGroup(
        monday: m,
        days: days,
        present: present,
        late: late,
        onLeave: onLeave,
        absent: absent,
        hoursWorked: worked,
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    final isFiltered = _viewModel.filter != DayFilter.all;
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
            Text(isFiltered ? 'No matches' : 'No working days',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'No days match this filter in '
                      '${DateFormat('MMMM yyyy').format(_viewModel.selectedMonth)}'
                  : 'No working days found for '
                      '${DateFormat('MMMM yyyy').format(_viewModel.selectedMonth)}',
              textAlign: TextAlign.center,
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
