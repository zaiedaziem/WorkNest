import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/attendance_viewmodel.dart';
import '../../../theme/app_theme.dart';
import 'day_status_badge.dart';
import 'day_time_chip.dart';

class DayCard extends StatelessWidget {
  final DayRecord record;
  const DayCard({super.key, required this.record});

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
      case DayStatus.weekend:
        return (
          color: const Color(0xFFCBD5E1),
          label: 'Weekend',
          icon: Icons.weekend_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeekend = record.status == DayStatus.weekend;

    if (isWeekend) {
      final date = record.date;
      final dayName = DateFormat('EEE').format(date);
      final dayNum = DateFormat('d').format(date);
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9EEF3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayName,
                      style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                  Text(dayNum,
                      style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Icon(Icons.weekend_rounded,
                size: 14, color: Color(0xFFCBD5E1)),
            const SizedBox(width: 6),
            const Text('Weekend',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    final cfg = _statusConfig();
    final date = record.date;
    final dayName = DateFormat('EEE').format(date);
    final dayNum = DateFormat('dd').format(date);
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
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
                      DayStatusBadge(
                          label: cfg.label,
                          color: cfg.color,
                          icon: cfg.icon),
                      if (hasAttendance && att.type == 'wfh') ...[
                        const SizedBox(width: 4),
                        DayStatusBadge(
                            label: 'WFH', color: AppTheme.secondary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildSubRow(),
                ],
              ),
            ),
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
            DayTimeChip(
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
            DayTimeChip(
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
      case DayStatus.weekend:
        return const SizedBox.shrink();
    }
  }
}
