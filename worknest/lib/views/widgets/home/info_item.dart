import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class HomeInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const HomeInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppTheme.primary, size: 18),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark)),
      ],
    );
  }
}
