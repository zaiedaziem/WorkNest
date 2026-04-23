import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/attendance_viewmodel.dart';
import '../../widgets/haptic_refresh_indicator.dart';

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
        label: 'On Leave',
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          for (final c in chips) ...[
            _FilterChip(
              label: c.label,
              count: c.count,
              color: c.color,
              isSelected: _viewModel.filter == c.filter,
              onTap: () => _viewModel.setFilter(c.filter),
            ),
            const SizedBox(width: 8),
          ],
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

  // ── Summary cards (hero row: hours worked + on-time rate) ─────────────────

  Widget _buildSummaryCards() {
    final rate = _viewModel.onTimeRate;
    return Row(
      children: [
        Expanded(
          child: _HeroCard(
            icon: Icons.schedule_rounded,
            value: _viewModel.totalHoursWorkedText,
            label: 'Hours Worked',
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OnTimeCard(
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
          _WeekHeader(group: g),
          const SizedBox(height: 8),
          ...g.days.map((r) => _DayCard(record: r)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// Group day records by ISO week (Mon–Sun). Weeks are returned in the same
  /// order as the input (already sorted most-recent-first).
  List<_WeekGroup> _groupByWeek(List<DayRecord> records) {
    final byMonday = <DateTime, List<DayRecord>>{};

    for (final r in records) {
      // Monday of that week
      final monday = r.date.subtract(Duration(days: r.date.weekday - 1));
      final mondayOnly = DateTime(monday.year, monday.month, monday.day);
      byMonday.putIfAbsent(mondayOnly, () => []).add(r);
    }

    // Sort weeks newest first (by Monday desc)
    final mondays = byMonday.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return mondays.map((m) {
      final days = byMonday[m]!;
      // Ensure days within a week are newest first
      days.sort((a, b) => b.date.compareTo(a.date));

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
            break;
        }
        final dur = d.attendance?.duration;
        if (dur != null) worked += dur;
      }

      return _WeekGroup(
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

// ── Hero card (Hours Worked) ──────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HeroCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── On-Time Rate card (with progress ring) ────────────────────────────────────

class _OnTimeCard extends StatelessWidget {
  final double? rate; // 0.0–1.0 or null when no data
  final String valueText;

  const _OnTimeCard({required this.rate, required this.valueText});

  Color _colorForRate(double? r) {
    if (r == null) return AppTheme.textMuted;
    if (r >= 0.9) return AppTheme.success;
    if (r >= 0.7) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForRate(rate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress ring with icon
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: rate ?? 0,
                    strokeWidth: 4,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Icon(Icons.check_rounded, color: color, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            valueText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'On-Time Rate',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
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

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weekly group ──────────────────────────────────────────────────────────────

class _WeekGroup {
  final DateTime monday;
  final List<DayRecord> days;
  final int present;
  final int late;
  final int onLeave;
  final int absent;
  final Duration hoursWorked;

  _WeekGroup({
    required this.monday,
    required this.days,
    required this.present,
    required this.late,
    required this.onLeave,
    required this.absent,
    required this.hoursWorked,
  });
}

class _WeekHeader extends StatelessWidget {
  final _WeekGroup group;
  const _WeekHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    // Working-week range: Monday to Friday
    final friday = group.monday.add(const Duration(days: 4));

    final sameMonth = group.monday.month == friday.month;
    final rangeLabel = sameMonth
        ? '${DateFormat('d').format(group.monday)} – ${DateFormat('d MMM').format(friday)}'
        : '${DateFormat('d MMM').format(group.monday)} – ${DateFormat('d MMM').format(friday)}';

    final h = group.hoursWorked.inHours;
    final m = group.hoursWorked.inMinutes.remainder(60);
    final hoursLabel = group.hoursWorked == Duration.zero
        ? null
        : (h > 0 ? '${h}h ${m}m' : '${m}m');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_view_week_rounded,
              size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            'Week of $rangeLabel',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _buildSummaryLine(hoursLabel),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSummaryLine(String? hoursLabel) {
    final parts = <String>[];
    final presentTotal = group.present + group.late;
    if (presentTotal > 0) parts.add('$presentTotal present');
    if (group.onLeave > 0) parts.add('${group.onLeave} leave');
    if (group.absent > 0) parts.add('${group.absent} absent');
    if (hoursLabel != null) parts.add(hoursLabel);
    return parts.join(' · ');
  }
}
