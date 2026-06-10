import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
