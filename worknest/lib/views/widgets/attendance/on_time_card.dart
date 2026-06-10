import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class OnTimeCard extends StatelessWidget {
  final double? rate;
  final String valueText;

  const OnTimeCard({super.key, required this.rate, required this.valueText});

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
          Text(valueText,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          const Text('On-Time Rate',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
