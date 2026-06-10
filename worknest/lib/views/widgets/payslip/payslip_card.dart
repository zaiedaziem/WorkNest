import 'package:flutter/material.dart';
import '../../../models/payslip_model.dart';
import '../../../theme/app_theme.dart';

class PayslipCard extends StatelessWidget {
  final PayslipModel payslip;
  final VoidCallback onTap;

  const PayslipCard({super.key, required this.payslip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isReleased = payslip.status == 'finalized';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isReleased
                ? const Color(0xFFBBF7D0)
                : const Color(0xFFF3F4F6),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isReleased
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isReleased
                      ? Icons.receipt_long_rounded
                      : Icons.hourglass_empty_rounded,
                  color: isReleased ? AppTheme.success : AppTheme.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payslip.monthName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isReleased
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isReleased ? 'Released' : 'Not Released Yet',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isReleased
                              ? AppTheme.success
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isReleased
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
                color: isReleased
                    ? AppTheme.textMuted
                    : const Color(0xFFD97706),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
