import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class InlineError extends StatelessWidget {
  final String message;
  const InlineError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 13, color: AppTheme.danger),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
