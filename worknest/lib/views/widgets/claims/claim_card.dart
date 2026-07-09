import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/claim_model.dart';
import '../../../theme/app_theme.dart';

class ClaimCard extends StatelessWidget {
  final ClaimModel claim;
  const ClaimCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (claim.status) {
      'approved' => AppTheme.success,
      'rejected' => AppTheme.danger,
      _ => AppTheme.warning,
    };
    final typeColor = switch (claim.claimType) {
      'travel' => const Color(0xFF0891B2),
      'accommodation' => const Color(0xFF4361EE),
      'subsistence' => const Color(0xFFF97316),
      _ => AppTheme.textMuted,
    };
    final typeIcon = switch (claim.claimType) {
      'travel' => Icons.directions_car_rounded,
      'accommodation' => Icons.hotel_rounded,
      'subsistence' => Icons.restaurant_rounded,
      _ => Icons.receipt_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(typeIcon, color: typeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(claim.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(claim.typeLabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: typeColor,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.3))),
                child: Text(
                  claim.status[0].toUpperCase() + claim.status.substring(1),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(DateFormat('d MMM yyyy').format(claim.claimDate),
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (claim.status == 'approved' &&
                      claim.approvedAmount != null)
                    Text('RM ${claim.approvedAmount!.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.success)),
                  Text(
                    claim.status == 'approved' && claim.approvedAmount != null
                        ? 'Claimed: RM ${claim.amount.toStringAsFixed(2)}'
                        : 'RM ${claim.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize:
                            claim.status == 'approved' &&
                                    claim.approvedAmount != null
                                ? 11
                                : 15,
                        fontWeight:
                            claim.status == 'approved' &&
                                    claim.approvedAmount != null
                                ? FontWeight.normal
                                : FontWeight.w800,
                        color: claim.status == 'approved' &&
                                claim.approvedAmount != null
                            ? AppTheme.textMuted
                            : (claim.exceedsPolicy
                                ? AppTheme.warning
                                : AppTheme.textDark)),
                  ),
                  if (claim.suggestedAmount != null &&
                      claim.status != 'approved')
                    Text(
                        'Policy: RM ${claim.suggestedAmount!.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          if (claim.exceedsPolicy) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 12, color: AppTheme.warning),
                const SizedBox(width: 4),
                const Text('Amount exceeds policy rate — pending HR review',
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.warning)),
              ],
            ),
          ],
          if (claim.receiptUrl != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.attach_file_rounded,
                    size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                const Text('Receipt attached',
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ],
          if (claim.rejectionReason != null &&
              claim.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.comment_rounded,
                      size: 12, color: AppTheme.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('HR: ${claim.rejectionReason}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.danger,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
