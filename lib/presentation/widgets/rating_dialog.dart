import 'package:flutter/material.dart';
import '../../core/theme/dark_neon_theme.dart';
import '../../core/widgets/bouncy_tap_wrapper.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/neon_button.dart';

class RatingDialog extends StatefulWidget {
  final String wallpaperTitle;
  final Function(int rating) onRatingSubmitted;

  const RatingDialog({
    super.key,
    required this.wallpaperTitle,
    required this.onRatingSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required String wallpaperTitle,
    required Function(int) onRatingSubmitted,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => RatingDialog(
        wallpaperTitle: wallpaperTitle,
        onRatingSubmitted: onRatingSubmitted,
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _selectedRating = 5;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.transparent,
          child: LiquidGlassContainer(
            borderRadius: 24,
            borderColor: DarkNeonTheme.primaryNeon.withOpacity(0.8),
            enableGlow: true,
            glowColor: DarkNeonTheme.primaryNeon,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Rate Wallpaper',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.wallpaperTitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: DarkNeonTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    final isFilled = starIndex <= _selectedRating;

                    return BouncyTapWrapper(
                      onTap: () => setState(() => _selectedRating = starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                          color: isFilled ? Colors.amber : Colors.white24,
                          size: 38,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: NeonButton(
                        text: 'SUBMIT RATING',
                        isFilled: true,
                        neonColor: DarkNeonTheme.primaryNeon,
                        onPressed: () {
                          widget.onRatingSubmitted(_selectedRating);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
