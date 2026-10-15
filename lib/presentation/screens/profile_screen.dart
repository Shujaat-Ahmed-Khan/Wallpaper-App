import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/dark_neon_theme.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/neon_button.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenCreatorStudio;

  const ProfileScreen({super.key, required this.onOpenCreatorStudio});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showCreatorSwitchModal() {
    final user = ref.read(currentUserProvider).asData?.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (_) => _BecomeCreatorSheet(initialUser: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: DarkNeonTheme.scaffoldBackground,
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            final isCreator = user.isCreator;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // App Bar Title
                  Row(
                    children: [
                      Text(
                        'PROFILE',
                        style: GoogleFonts.orbitron(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avatar & Header Box
                  LiquidGlassContainer(
                    borderRadius: 24,
                    borderColor: (isCreator ? DarkNeonTheme.creatorAccent : DarkNeonTheme.primaryNeon).withValues(alpha: 0.7),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Avatar with Neon Ring
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCreator ? DarkNeonTheme.creatorAccent : DarkNeonTheme.primaryNeon,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isCreator ? DarkNeonTheme.creatorAccent : DarkNeonTheme.primaryNeon).withValues(alpha: 0.40),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: user.avatarUrl.isNotEmpty
                                ? Image.network(
                                    user.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white70, size: 48),
                                  )
                                : const Icon(Icons.person, color: Colors.white70, size: 48),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user.displayName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 13, color: DarkNeonTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        // Role Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCreator
                                ? DarkNeonTheme.creatorAccent.withValues(alpha: 0.15)
                                : DarkNeonTheme.primaryNeon.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCreator ? DarkNeonTheme.creatorAccent : DarkNeonTheme.primaryNeon,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            isCreator ? 'VERIFIED CREATOR' : 'CYBER EXPLORER',
                            style: TextStyle(
                              color: isCreator ? DarkNeonTheme.creatorAccent : DarkNeonTheme.primaryNeon,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (user.bio.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            user.bio,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    children: [
                      _buildProfileStat('FOLLOWERS', user.stats.totalFollowers.toString(), DarkNeonTheme.primaryNeon),
                      const SizedBox(width: 12),
                      _buildProfileStat('UPLOADS', user.stats.totalUploads.toString(), DarkNeonTheme.creatorAccent),
                      const SizedBox(width: 12),
                      _buildProfileStat('RATING', user.stats.averageRating > 0 ? user.stats.averageRating.toStringAsFixed(1) : '5.0', Colors.amber),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  if (!isCreator) ...[
                    NeonButton(
                      text: 'SWITCH TO CREATOR MODE',
                      isFilled: true,
                      neonColor: DarkNeonTheme.creatorAccent,
                      icon: Icons.rocket_launch_rounded,
                      onPressed: _showCreatorSwitchModal,
                    ),
                  ] else ...[
                    NeonButton(
                      text: 'OPEN CREATOR DASHBOARD',
                      isFilled: true,
                      neonColor: DarkNeonTheme.creatorAccent,
                      icon: Icons.dashboard_customize_rounded,
                      onPressed: widget.onOpenCreatorStudio,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // App Information Settings List
                  LiquidGlassContainer(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _buildSettingItem(Icons.info_outline, 'About NeonGlass Engine', 'v1.0.0 (Hybrid Gyro Parallax)'),
                        const Divider(color: Colors.white10),
                        _buildSettingItem(Icons.policy_outlined, 'Pixabay API License', 'Complying with 24-hour cache terms'),
                        const Divider(color: Colors.white10),
                        _buildSettingItem(Icons.sensors, 'Sensor Calibration', '60 FPS Low-pass Rotation Vector'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: DarkNeonTheme.primaryNeon)),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: DarkNeonTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DarkNeonTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: DarkNeonTheme.primaryNeon, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: DarkNeonTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BecomeCreatorSheet extends ConsumerStatefulWidget {
  final UserModel? initialUser;

  const _BecomeCreatorSheet({this.initialUser});

  @override
  ConsumerState<_BecomeCreatorSheet> createState() => _BecomeCreatorSheetState();
}

class _BecomeCreatorSheetState extends ConsumerState<_BecomeCreatorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _bioFocus = FocusNode();
  bool _isLoading = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialUser?.displayName ?? '');
    _bioController = TextEditingController(text: widget.initialUser?.bio ?? '');

    _nameFocus.addListener(() => setState(() {}));
    _bioFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _nameFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _nameError = 'Please enter your creator or studio name';
      });
      _nameFocus.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
      _nameError = null;
    });

    try {
      await ref.read(currentUserProvider.notifier).switchToCreatorMode(name, bio);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DarkNeonTheme.creatorAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.black, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Creator Mode Activated! Studio is now unlocked.',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to activate creator mode: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final safeBottom = mediaQuery.padding.bottom;
    final bottomPadding = bottomInset > 0 ? bottomInset + 16.0 : (safeBottom > 0 ? safeBottom + 16.0 : 24.0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF10131B), // Solid, near-opaque dark background
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: DarkNeonTheme.creatorAccent.withValues(alpha: 0.50),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: DarkNeonTheme.creatorAccent.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 14,
            bottom: bottomPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Centered Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Title Row with Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'BECOME A NEON CREATOR',
                      style: GoogleFonts.orbitron(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: DarkNeonTheme.creatorAccent,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: DarkNeonTheme.creatorAccent.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // Title-to-description spacing: 12px
              const SizedBox(height: 12),

              // Description
              const Text(
                'Unlock your Creator Studio, upload 4K/Live/3D wallpapers, and build your follower base across the NeonGlass network.',
                style: TextStyle(
                  color: Color(0xFF94A3B8), // Crisp light slate
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),

              // Description-to-first-field spacing: 24px
              const SizedBox(height: 24),

              // Label 1: Creator Name (8px to input)
              const Text(
                'CREATOR / STUDIO NAME',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),

              // Input 1: Creator Name
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _nameError != null
                        ? Colors.redAccent
                        : (_nameFocus.hasFocus
                            ? DarkNeonTheme.creatorAccent
                            : Colors.white.withValues(alpha: 0.12)),
                    width: _nameFocus.hasFocus ? 1.5 : 1.2,
                  ),
                  boxShadow: _nameFocus.hasFocus
                      ? [
                          BoxShadow(
                            color: DarkNeonTheme.creatorAccent.withValues(alpha: 0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                  decoration: const InputDecoration(
                    hintText: 'e.g. CyberVisions, NeonSamurai',
                    hintStyle: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: DarkNeonTheme.creatorAccent,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              if (_nameError != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _nameError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],

              // Between form fields: 20px
              const SizedBox(height: 20),

              // Label 2: Creator Bio (8px to input)
              const Text(
                'CREATOR BIO',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),

              // Input 2: Creator Bio (Multi-line textarea)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _bioFocus.hasFocus
                        ? DarkNeonTheme.creatorAccent
                        : Colors.white.withValues(alpha: 0.12),
                    width: _bioFocus.hasFocus ? 1.5 : 1.2,
                  ),
                  boxShadow: _bioFocus.hasFocus
                      ? [
                          BoxShadow(
                            color: DarkNeonTheme.creatorAccent.withValues(alpha: 0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 14, left: 14, right: 4),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: DarkNeonTheme.creatorAccent,
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _bioController,
                        focusNode: _bioFocus,
                        minLines: 3,
                        maxLines: 4,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tell your future followers about your artistic style, 3D engines, or aesthetic vision...',
                          hintStyle: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            height: 1.4,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(right: 16, top: 14, bottom: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Final field-to-CTA spacing: 24px
              const SizedBox(height: 24),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DarkNeonTheme.creatorAccent,
                    disabledBackgroundColor: DarkNeonTheme.creatorAccent.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: DarkNeonTheme.creatorAccent.withValues(alpha: 0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A0E17)),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.rocket_launch_rounded,
                              color: Color(0xFF0A0E17),
                              size: 19,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'ACTIVATE CREATOR MODE',
                              style: TextStyle(
                                color: Color(0xFF0A0E17),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
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
  }
}
