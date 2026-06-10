import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/attendance_model.dart';
import '../../../theme/app_theme.dart';
import 'status_badge.dart';

class RecentAttendanceRow extends StatelessWidget {
  final AttendanceModel record;
  const RecentAttendanceRow({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final isLate = record.status == 'late';
    final statusColor = isLate ? AppTheme.warning : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('EEE').format(record.date),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary)),
                Text(DateFormat('dd').format(record.date),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('d MMM yyyy').format(record.date),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
                const SizedBox(height: 3),
                Text(
                  '${record.clockIn != null ? DateFormat('hh:mm a').format(record.clockIn!) : '-'}'
                  '  →  '
                  '${record.clockOut != null ? DateFormat('hh:mm a').format(record.clockOut!) : 'Working...'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(
                  label: isLate ? 'Late' : 'Present',
                  color: statusColor),
              if (record.duration != null) ...[
                const SizedBox(height: 4),
                Text(record.durationText,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
