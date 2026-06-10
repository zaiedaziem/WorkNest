import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class DateSummaryRow extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isHalfDay;
  final VoidCallback onClear;

  const DateSummaryRow({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.isHalfDay,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (startDate == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Text(
          'Tap a date to start. Tap another to set the end date.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      );
    }

    final fmt = DateFormat('d MMM yyyy');
    String label;

    if (isHalfDay) {
      label = fmt.format(startDate!);
    } else if (endDate == null) {
      label = '${fmt.format(startDate!)}  →  tap to set end';
    } else {
      final isSame = startDate!.year == endDate!.year &&
          startDate!.month == endDate!.month &&
          startDate!.day == endDate!.day;
      label = isSame
          ? fmt.format(startDate!)
          : '${fmt.format(startDate!)}  –  ${fmt.format(endDate!)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
