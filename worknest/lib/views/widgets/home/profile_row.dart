import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? note;

  const ProfileRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark),
                    overflow: TextOverflow.ellipsis),
                if (note != null)
                  Text(note!,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
