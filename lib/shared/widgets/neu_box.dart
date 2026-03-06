import 'package:flutter/material.dart';
import '../../app/theme.dart';

class NeuBox extends StatelessWidget {
  const NeuBox({
    super.key,
    required this.child,
    this.color,
    this.borderRadius = 16.0,
    this.shadowOffset = const Offset(4, 4),
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderWidth = AppColors.borderWidth,
  });

  final Widget child;
  final Color? color;
  final double borderRadius;
  final Offset shadowOffset;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.white : AppColors.black;
    final shadowColor = isDark ? AppColors.white : AppColors.black;
    final bgColor = color ?? Theme.of(context).colorScheme.surface;

    final box = Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: shadowOffset,
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: box);
    }
    return box;
  }
}
