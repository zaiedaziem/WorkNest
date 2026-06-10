import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/leave_request_model.dart';
import '../../../theme/app_theme.dart';

class HistoryCard extends StatelessWidget {
  final LeaveRequestModel request;
  final void Function(String) onCancel;

  const HistoryCard({
    super.key,
    required this.request,
    required this.onCancel,
  });

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
