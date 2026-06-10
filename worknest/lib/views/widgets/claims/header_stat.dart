import 'package:flutter/material.dart';

class ClaimHeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const ClaimHeaderStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }
}
