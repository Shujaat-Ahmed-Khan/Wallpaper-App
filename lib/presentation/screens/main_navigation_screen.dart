import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/dark_neon_theme.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'creator_dashboard_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final isCreator = userAsync.asData?.value.isCreator ?? false;

    // List of screens dynamically adapts to Creator Mode unlock
    final List<Widget> screens = [
      HomeScreen(
        onOpenProfile: () => setState(() => _currentIndex = isCreator ? 2 : 1),
        onOpenCreator: () {
          if (isCreator) {
            setState(() => _currentIndex = 1);
          } else {
            setState(() => _currentIndex = 1);
          }
        },
      ),
      if (isCreator) const CreatorDashboardScreen(),
      ProfileScreen(
        onOpenCreatorStudio: () => setState(() => _currentIndex = 1),
      ),
    ];

    // Ensure index doesn't exceed screen length if creator role toggled
    if (_currentIndex >= screens.length) {
      _currentIndex = screens.length - 1;
    }

    return Scaffold(
      backgroundColor: DarkNeonTheme.scaffoldBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: DarkNeonTheme.scaffoldBackground,
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: LiquidGlassContainer(
            borderRadius: 26,
            borderColor: Colors.white.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'EXPLORE',
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  color: DarkNeonTheme.primaryNeon,
                ),
                if (isCreator)
                  _buildNavItem(
                    index: 1,
                    label: 'STUDIO',
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    color: DarkNeonTheme.creatorAccent,
                  ),
                _buildNavItem(
                  index: isCreator ? 2 : 1,
                  label: 'PROFILE',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  color: DarkNeonTheme.secondaryNeon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required Color color,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: color, width: 1.2) : null,
          boxShadow: isSelected ? DarkNeonTheme.neonGlow(color, blur: 10, opacity: 0.4) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? color : DarkNeonTheme.textSecondary,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
