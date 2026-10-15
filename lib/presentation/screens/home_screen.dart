import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/dark_neon_theme.dart';
import '../../core/widgets/bouncy_tap_wrapper.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/neon_button.dart';
import '../../data/models/wallpaper_model.dart';
import '../providers/wallpaper_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/staggered_wallpaper_grid.dart';
import 'detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenCreator;

  const HomeScreen({
    super.key,
    required this.onOpenProfile,
    required this.onOpenCreator,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).setQuery(value);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedType = ref.watch(selectedTypeFilterProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final wallpapersAsync = ref.watch(wallpapersListProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: DarkNeonTheme.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                children: [
                  // App Branding
                  Expanded(
                    child: _isSearching
                        ? Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: DarkNeonTheme.cardSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: DarkNeonTheme.primaryNeon.withOpacity(0.6)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              autofocus: true,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search 4K neon wallpapers...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                                prefixIcon: const Icon(Icons.search, color: DarkNeonTheme.primaryNeon, size: 20),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _isSearching = false;
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Text(
                                'NEON',
                                style: GoogleFonts.orbitron(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: DarkNeonTheme.primaryNeon,
                                  letterSpacing: 1.5,
                                  shadows: DarkNeonTheme.neonGlow(DarkNeonTheme.primaryNeon, blur: 16, opacity: 0.8),
                                ),
                              ),
                              Text(
                                'GLASS',
                                style: GoogleFonts.orbitron(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: DarkNeonTheme.secondaryNeon,
                                  letterSpacing: 1.5,
                                  shadows: DarkNeonTheme.neonGlow(DarkNeonTheme.secondaryNeon, blur: 16, opacity: 0.8),
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Header Action Buttons
                  if (!_isSearching) ...[
                    BouncyTapWrapper(
                      onTap: () => setState(() => _isSearching = true),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: DarkNeonTheme.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.search, color: DarkNeonTheme.primaryNeon, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // Avatar / Profile Shortcut
                  BouncyTapWrapper(
                    onTap: widget.onOpenProfile,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: DarkNeonTheme.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: userAsync.asData?.value.isCreator == true
                              ? DarkNeonTheme.creatorAccent
                              : DarkNeonTheme.primaryNeon.withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: userAsync.asData?.value.isCreator == true
                            ? DarkNeonTheme.neonGlow(DarkNeonTheme.creatorAccent, blur: 8, opacity: 0.5)
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: userAsync.asData?.value.avatarUrl.isNotEmpty == true
                            ? Image.network(
                                userAsync.asData!.value.avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(Icons.person, color: Colors.white70, size: 20),
                              )
                            : const Icon(Icons.person, color: Colors.white70, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Horizontal Tabs
            SizedBox(
              height: 46,
              child: categoriesAsync.when(
                data: (categories) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = cat.id == selectedCategory;

                      return BouncyTapWrapper(
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).setCategory(cat.id);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? DarkNeonTheme.primaryNeon.withOpacity(0.15)
                                : DarkNeonTheme.cardSurface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? DarkNeonTheme.primaryNeon
                                  : Colors.white.withOpacity(0.1),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? DarkNeonTheme.neonGlow(DarkNeonTheme.primaryNeon, blur: 12, spread: 1, opacity: 0.45)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                color: isSelected ? DarkNeonTheme.primaryNeon : DarkNeonTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SizedBox(height: 10),

            // Engine Type Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTypeFilterChip(
                    label: 'ALL',
                    isSelected: selectedType == null,
                    color: Colors.white,
                    onTap: () => ref.read(selectedTypeFilterProvider.notifier).setType(null),
                  ),
                  const SizedBox(width: 8),
                  _buildTypeFilterChip(
                    label: 'STATIC',
                    icon: Icons.image_rounded,
                    isSelected: selectedType == WallpaperType.STATIC,
                    color: DarkNeonTheme.creatorAccent,
                    onTap: () => ref.read(selectedTypeFilterProvider.notifier).setType(WallpaperType.STATIC),
                  ),
                  const SizedBox(width: 8),
                  _buildTypeFilterChip(
                    label: 'LIVE',
                    icon: Icons.play_arrow_rounded,
                    isSelected: selectedType == WallpaperType.LIVE,
                    color: DarkNeonTheme.secondaryNeon,
                    onTap: () => ref.read(selectedTypeFilterProvider.notifier).setType(WallpaperType.LIVE),
                  ),
                  const SizedBox(width: 8),
                  _buildTypeFilterChip(
                    label: '3D GYRO',
                    icon: Icons.screen_rotation_outlined,
                    isSelected: selectedType == WallpaperType.GYRO,
                    color: DarkNeonTheme.primaryNeon,
                    onTap: () => ref.read(selectedTypeFilterProvider.notifier).setType(WallpaperType.GYRO),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Wallpapers Grid
            Expanded(
              child: wallpapersAsync.when(
                data: (wallpapers) {
                  return RefreshIndicator(
                    color: DarkNeonTheme.primaryNeon,
                    backgroundColor: DarkNeonTheme.cardSurface,
                    onRefresh: () async {
                      ref.invalidate(wallpapersListProvider);
                    },
                    child: StaggeredWallpaperGrid(
                      wallpapers: wallpapers,
                      onWallpaperSelected: (wallpaper) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(wallpaper: wallpaper),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(DarkNeonTheme.primaryNeon),
                  ),
                ),
                error: (err, stack) => Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: LiquidGlassContainer(
                      padding: const EdgeInsets.all(24),
                      borderColor: DarkNeonTheme.secondaryNeon.withOpacity(0.5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: DarkNeonTheme.secondaryNeon, size: 48),
                          const SizedBox(height: 14),
                          const Text(
                            'OFFLINE PREVIEW ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Displaying offline catalog. Tap reload to re-sync with online feed.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          NeonButton(
                            text: 'RELOAD FEED',
                            icon: Icons.refresh,
                            neonColor: DarkNeonTheme.primaryNeon,
                            onPressed: () => ref.invalidate(wallpapersListProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BouncyTapWrapper(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.15),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? color : DarkNeonTheme.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : DarkNeonTheme.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
