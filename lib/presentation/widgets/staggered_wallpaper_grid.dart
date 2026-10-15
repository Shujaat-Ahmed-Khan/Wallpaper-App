import 'package:flutter/material.dart';
import '../../data/models/wallpaper_model.dart';
import 'wallpaper_card.dart';

class StaggeredWallpaperGrid extends StatelessWidget {
  final List<WallpaperModel> wallpapers;
  final Function(WallpaperModel) onWallpaperSelected;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry padding;

  const StaggeredWallpaperGrid({
    super.key,
    required this.wallpapers,
    required this.onWallpaperSelected,
    this.scrollController,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    if (wallpapers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 64),
            SizedBox(height: 12),
            Text(
              'No Wallpapers Found',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Try changing category or search terms',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: scrollController,
      padding: padding,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.58, // Tall mobile wallpaper aspect ratio
      ),
      itemCount: wallpapers.length,
      itemBuilder: (context, index) {
        final wallpaper = wallpapers[index];
        return WallpaperCard(
          wallpaper: wallpaper,
          onTap: () => onWallpaperSelected(wallpaper),
        );
      },
    );
  }
}
