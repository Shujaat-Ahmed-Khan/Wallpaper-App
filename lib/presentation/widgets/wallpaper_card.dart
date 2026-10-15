import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/dark_neon_theme.dart';
import '../../core/widgets/bouncy_tap_wrapper.dart';
import '../../data/models/wallpaper_model.dart';

class WallpaperCard extends StatelessWidget {
  final WallpaperModel wallpaper;
  final VoidCallback onTap;

  const WallpaperCard({
    super.key,
    required this.wallpaper,
    required this.onTap,
  });

  Color _getTypeColor(WallpaperType type) {
    switch (type) {
      case WallpaperType.GYRO:
        return DarkNeonTheme.primaryNeon; // Electric Cyan
      case WallpaperType.LIVE:
        return DarkNeonTheme.secondaryNeon; // Cyber Magenta
      case WallpaperType.STATIC:
        return DarkNeonTheme.creatorAccent; // Neon Lime
    }
  }

  IconData _getTypeIcon(WallpaperType type) {
    switch (type) {
      case WallpaperType.GYRO:
        return Icons.screen_rotation_outlined;
      case WallpaperType.LIVE:
        return Icons.play_arrow_rounded;
      case WallpaperType.STATIC:
        return Icons.image_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(wallpaper.type);

    return BouncyTapWrapper(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DarkNeonTheme.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Memory cached thumbnail (Strict Grid Optimization: never raw 4K or mp4)
              CachedNetworkImage(
                imageUrl: wallpaper.thumbnailUrl,
                memCacheWidth: 350,
                memCacheHeight: 600,
                maxWidthDiskCache: 500,
                maxHeightDiskCache: 850,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: DarkNeonTheme.cardSurface,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(DarkNeonTheme.primaryNeon.withOpacity(0.6)),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: DarkNeonTheme.cardSurface,
                  child: const Icon(Icons.broken_image_rounded, color: Colors.white30, size: 32),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.35),
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Top Badges: Type & Rating
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Engine Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DarkNeonTheme.cardSurface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: typeColor.withOpacity(0.8), width: 1.2),
                        boxShadow: DarkNeonTheme.neonGlow(typeColor, blur: 8, spread: 0.5, opacity: 0.4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getTypeIcon(wallpaper.type), color: typeColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            wallpaper.type.name,
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rating Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            wallpaper.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Title & Creator Info
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      wallpaper.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 11, color: DarkNeonTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            wallpaper.uploaderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DarkNeonTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
