import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/attendance_viewmodel.dart';
import '../../../theme/app_theme.dart';

/// Data class grouping days by ISO week.
class WeekGroup {
  final DateTime monday;
  final List<DayRecord> days;
  final int present;
  final int late;
  final int onLeave;
  final int absent;
  final Duration hoursWorked;

  WeekGroup({
    required this.monday,
    required this.days,
    required this.present,
    required this.late,
    required this.onLeave,
    required this.absent,
    required this.hoursWorked,
  });
}

class WeekHeader extends StatelessWidget {
  final WeekGroup group;
  const WeekHeader({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final sunday = group.monday.add(const Duration(days: 6));

    final sameMonth = group.monday.month == sunday.month;
    final rangeLabel = sameMonth
        ? '${DateFormat('d').format(group.monday)} – ${DateFormat('d MMM').format(sunday)}'
        : '${DateFormat('d MMM').format(group.monday)} – ${DateFormat('d MMM').format(sunday)}';

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
