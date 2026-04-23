import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Drop-in replacement for [RefreshIndicator] that triggers a medium
/// haptic buzz when the user pulls to refresh. Use everywhere in the app
/// for consistent feel.
class HapticRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color color;

  const HapticRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: color,
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await onRefresh();
      },
      child: child,
    );
  }
}
