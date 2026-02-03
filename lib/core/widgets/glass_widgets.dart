import 'package:flutter/material.dart';

/// Performant glass card - uses solid semi-transparent color instead of blur.
/// Provides a consistent glassmorphic appearance across the app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.color,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// Glass Chip for compact labeled displays.
class GlassChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color labelColor;
  final double borderRadius;

  const GlassChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.labelColor,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(color: labelColor, fontWeight: FontWeight.w500),
      ),
    );
  }
}
