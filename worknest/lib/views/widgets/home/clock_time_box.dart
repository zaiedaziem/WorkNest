import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ClockTimeBox extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;

  const ClockTimeBox({
    super.key,
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(time,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
