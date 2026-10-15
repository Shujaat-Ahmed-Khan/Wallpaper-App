import 'package:flutter/material.dart';
import '../theme/dark_neon_theme.dart';
import 'bouncy_tap_wrapper.dart';
import 'liquid_glass_container.dart';

class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color neonColor;
  final bool isFilled;
  final double height;
  final double? width;
  final double borderRadius;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const NeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.neonColor = DarkNeonTheme.primaryNeon,
    this.isFilled = false,
    this.height = 50.0,
    this.width,
    this.borderRadius = 16.0,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyTapWrapper(
      onTap: isLoading ? null : onPressed,
      child: isFilled
          ? Container(
              height: height,
              width: width,
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  colors: [
                    neonColor,
                    neonColor.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: DarkNeonTheme.neonGlow(neonColor, blur: 18, spread: 2, opacity: 0.5),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            text,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            )
          : LiquidGlassContainer(
              height: height,
              width: width,
              borderRadius: borderRadius,
              borderColor: neonColor.withValues(alpha: 0.8),
              enableGlow: true,
              glowColor: neonColor,
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(neonColor),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: neonColor, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            text,
                            style: TextStyle(
                              color: neonColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }
}
