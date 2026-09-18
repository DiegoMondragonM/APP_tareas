import 'package:flutter/material.dart';
import 'package:aptar/theme/app_theme.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final bool clip;

  const DashboardCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 14),
    this.color,
    this.clip = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
        boxShadow: AppDecorations.cardShadow,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );

    if (onTap == null) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          color: color ?? AppColors.card,
          borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
          boxShadow: AppDecorations.cardShadow,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
          clipBehavior: clip ? Clip.antiAlias : Clip.none,
          child: Padding(padding: padding, child: child),
        ),
      );
    }

    return content;
  }
}
