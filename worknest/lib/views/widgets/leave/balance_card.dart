import 'package:flutter/material.dart';
import '../../../models/leave_balance_model.dart';
import '../../../theme/app_theme.dart';

class BalanceCard extends StatelessWidget {
  final LeaveBalanceModel balance;
  const BalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final used = balance.usedDays;
    final pending = balance.pendingDays;
    final remaining = balance.remainingDays;
    final total = balance.totalDays.toDouble();
    final progress = total > 0 ? (used + pending) / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                balance.leavePolicyName,
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
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${remaining % 1 == 0 ? remaining.toInt() : remaining} / ${balance.totalDays} days',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? AppTheme.danger : AppTheme.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              BalanceStat(label: 'Used', value: used, color: AppTheme.danger),
              const SizedBox(width: 16),
              BalanceStat(
                label: 'Pending',
                value: pending,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 16),
              BalanceStat(
                label: 'Remaining',
                value: remaining,
                color: AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BalanceStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const BalanceStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final display =
        value % 1 == 0 ? value.toInt().toString() : value.toString();
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$display $label',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
