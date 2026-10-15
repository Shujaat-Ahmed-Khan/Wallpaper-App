import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/dark_neon_theme.dart';

class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? glowColor;
  final double borderWidth;
  final bool enableGlow;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final bool useBlur;
  final VoidCallback? onTap;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.borderColor,
    this.glowColor,
    this.borderWidth = 1.2,
    this.enableGlow = false,
    this.useBlur = false,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? Colors.white.withOpacity(0.18);
    final effectiveGlow = enableGlow && glowColor != null
        ? DarkNeonTheme.neonGlow(glowColor!, blur: 16, spread: 1)
        : <BoxShadow>[];

    final glassBox = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: DarkNeonTheme.cardSurface.withOpacity(0.85),
        gradient: LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: [
            Colors.white.withOpacity(0.12),
            DarkNeonTheme.cardSurface.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: effectiveGlow,
      ),
      child: useBlur
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: glassBox,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: glassBox,
            ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
