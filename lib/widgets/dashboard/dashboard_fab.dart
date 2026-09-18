import 'package:flutter/material.dart';
import 'package:aptar/theme/app_theme.dart';

class DashboardFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const DashboardFab({
    super.key,
    required this.onPressed,
    this.tooltip = 'Crear',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDecorations.fabShadow,
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}
