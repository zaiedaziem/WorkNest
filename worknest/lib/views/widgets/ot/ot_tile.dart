import 'package:flutter/material.dart';
import '../../../models/ot_request_model.dart';
import '../../../theme/app_theme.dart';

class OtTile extends StatelessWidget {
  final OtRequestModel request;
  const OtTile({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final isApproved = request.status == 'approved';
    final isPending = request.status == 'pending';

    final statusColor = isApproved
        ? AppTheme.success
        : isPending
            ? const Color(0xFFF59E0B)
            : AppTheme.danger;
    final statusLabel = isApproved
        ? 'Approved'
        : isPending
            ? 'Pending'
            : 'Rejected';
    final statusIcon = isApproved
        ? Icons.check_circle_rounded
        : isPending
            ? Icons.hourglass_top_rounded
            : Icons.cancel_rounded;

    final typeLabel = request.otType == 'holiday'
        ? 'Public Holiday'
        : request.otType == 'restday'
            ? 'Rest Day'
            : 'Weekday';
    final typeColor = request.otType == 'holiday'
        ? AppTheme.danger
        : request.otType == 'restday'
            ? const Color(0xFFF59E0B)
            : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(typeLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: typeColor)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(request.displayDate,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
                const SizedBox(width: 14),
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                    '${request.displayStartTime} – ${request.displayEndTime}',
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textDark)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${request.otHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(request.reason,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textMuted)),
            if (request.hrRemarks != null &&
                request.hrRemarks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(request.hrRemarks!,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
