import 'package:flutter/material.dart';
import '../../core/theme/dark_neon_theme.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/neon_button.dart';

class IosInstructionalModal extends StatelessWidget {
  const IosInstructionalModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const IosInstructionalModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LiquidGlassContainer(
          borderRadius: 24,
          borderColor: DarkNeonTheme.primaryNeon.withOpacity(0.8),
          enableGlow: true,
          glowColor: DarkNeonTheme.primaryNeon,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DarkNeonTheme.creatorAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: DarkNeonTheme.creatorAccent, width: 1.5),
                      boxShadow: DarkNeonTheme.neonGlow(DarkNeonTheme.creatorAccent, blur: 12, opacity: 0.5),
                    ),
                    child: const Icon(Icons.check, color: DarkNeonTheme.creatorAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Saved to Photos Library',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildStepRow(
                stepNum: '1',
                title: 'Open iOS Settings',
                description: 'Go to your device home and launch Settings > Wallpaper.',
              ),
              const SizedBox(height: 14),
              _buildStepRow(
                stepNum: '2',
                title: 'Tap "Add New Wallpaper"',
                description: 'Select the "Photos" icon at the top of the gallery list.',
              ),
              const SizedBox(height: 14),
              _buildStepRow(
                stepNum: '3',
                title: 'Set Pair or Customize',
                description: 'Adjust crop, enable Depth Effect, and tap "Set as Wallpaper Pair".',
              ),
              const SizedBox(height: 24),
              NeonButton(
                text: 'GOT IT, OPEN PHOTOS',
                isFilled: true,
                neonColor: DarkNeonTheme.primaryNeon,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String stepNum,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: DarkNeonTheme.primaryNeon.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: DarkNeonTheme.primaryNeon),
          ),
          child: Center(
            child: Text(
              stepNum,
              style: const TextStyle(
                color: DarkNeonTheme.primaryNeon,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: DarkNeonTheme.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
