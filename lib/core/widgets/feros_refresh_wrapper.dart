import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Wraps any scrollable child with pull-to-refresh.
class FerosRefreshWrapper extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const FerosRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.orange,
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      child: child,
    );
  }
}
