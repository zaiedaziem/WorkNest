import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class DayTimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const DayTimeChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark)),
      ],
    );
  }
}
