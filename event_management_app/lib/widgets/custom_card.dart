import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? borderRadius;

  const CustomCard({
    super.key,
    required this.child,
    this.elevation = 2.0,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppTheme.white,
      elevation: elevation,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: InkWell(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
