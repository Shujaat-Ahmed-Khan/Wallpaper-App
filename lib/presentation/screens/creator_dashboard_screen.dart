import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/dark_neon_theme.dart';
import '../../core/widgets/bouncy_tap_wrapper.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/neon_button.dart';
import '../../data/models/wallpaper_model.dart';
import '../providers/auth_provider.dart';
import '../providers/wallpaper_providers.dart';
import '../widgets/creator_upload_modal.dart';
import 'detail_screen.dart';

class CreatorDashboardScreen extends ConsumerWidget {
  const CreatorDashboardScreen({super.key});

  Color _getStatusColor(WallpaperStatus status) {
    switch (status) {
      case WallpaperStatus.APPROVED:
        return DarkNeonTheme.creatorAccent; // Neon Lime
      case WallpaperStatus.PENDING:
        return DarkNeonTheme.warningNeon;   // Neon Amber
      case WallpaperStatus.REJECTED:
        return DarkNeonTheme.secondaryNeon; // Cyber Red/Magenta
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: DarkNeonTheme.scaffoldBackground,
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            final creatorWallpapersAsync = ref.watch(creatorWallpapersProvider(user.uid));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CREATOR STUDIO',
                                style: GoogleFonts.orbitron(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: DarkNeonTheme.creatorAccent,
                                  letterSpacing: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Welcome back, ${user.displayName}',
                                style: const TextStyle(color: DarkNeonTheme.textSecondary, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Quick Upload Button
                        NeonButton(
                          text: 'UPLOAD',
                          isFilled: true,
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          neonColor: DarkNeonTheme.creatorAccent,
                          icon: Icons.add_rounded,
                          onPressed: () => CreatorUploadModal.show(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pre-aggregated Neon Stat Header (1 Single Document Read)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        _buildStatCard(
                          label: 'FOLLOWERS',
                          value: user.stats.totalFollowers.toString(),
                          icon: Icons.people_outline_rounded,
                          color: DarkNeonTheme.primaryNeon,
                        ),
                        const SizedBox(width: 10),
                        _buildStatCard(
                          label: 'AVG RATING',
                          value: user.stats.averageRating > 0 ? user.stats.averageRating.toStringAsFixed(1) : '5.0',
                          icon: Icons.star_outline_rounded,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 10),
                        _buildStatCard(
                          label: 'UPLOADS',
                          value: user.stats.totalUploads.toString(),
                          icon: Icons.cloud_upload_outlined,
                          color: DarkNeonTheme.creatorAccent,
                        ),
                      ],
                    ),
                  ),
                ),

                // Section Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'YOUR UPLOAD HISTORY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white60, size: 20),
                          onPressed: () => ref.invalidate(creatorWallpapersProvider(user.uid)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Creator Uploads Grid
                creatorWallpapersAsync.when(
                  data: (wallpapers) {
                    if (wallpapers.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.palette_outlined, size: 56, color: Colors.white24),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Creations Yet',
                                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tap "+ UPLOAD" to submit your first neon wallpaper',
                                  style: TextStyle(color: Colors.white38, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = wallpapers[index];
                            final statusColor = _getStatusColor(item.status);

                            return BouncyTapWrapper(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DetailScreen(wallpaper: item),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: DarkNeonTheme.cardSurface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: item.thumbnailUrl,
                                        memCacheWidth: 400,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: DarkNeonTheme.cardSurface),
                                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white24),
                                      ),
                                      // Status Badge
                                      Positioned(
                                        top: 10,
                                        left: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: statusColor, width: 1.2),
                                            boxShadow: DarkNeonTheme.neonGlow(statusColor, blur: 8, opacity: 0.5),
                                          ),
                                          child: Text(
                                            item.status.name,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Title & Type Footer
                                      Positioned(
                                        left: 10,
                                        right: 10,
                                        bottom: 10,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.75),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.type.name,
                                                style: const TextStyle(
                                                  color: DarkNeonTheme.textSecondary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: wallpapers.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(color: DarkNeonTheme.creatorAccent),
                      ),
                    ),
                  ),
                  error: (err, _) => SliverToBoxAdapter(
                    child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white70))),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: DarkNeonTheme.creatorAccent)),
          error: (err, _) => Center(child: Text('Error loading user profile: $err')),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: LiquidGlassContainer(
        borderRadius: 18,
        borderColor: color.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: DarkNeonTheme.neonGlow(color, blur: 8, opacity: 0.5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: DarkNeonTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
