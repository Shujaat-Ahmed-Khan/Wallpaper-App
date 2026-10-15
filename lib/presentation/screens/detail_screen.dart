import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/dark_neon_theme.dart';
import '../../core/widgets/bouncy_tap_wrapper.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/services/wallpaper_channel_service.dart';
import '../../data/models/wallpaper_model.dart';
import '../providers/wallpaper_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/gyro_preview_widget.dart';
import '../widgets/ios_instructional_modal.dart';
import '../widgets/rating_dialog.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final WallpaperModel wallpaper;

  const DetailScreen({super.key, required this.wallpaper});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isMuted = true;
  bool _isApplying = false;
  bool _isFollowing = false;
  bool _showInfoSheet = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
    if (widget.wallpaper.type == WallpaperType.LIVE && widget.wallpaper.videoUrl != null) {
      _initVideoPlayer(widget.wallpaper.videoUrl!);
    }
  }

  Future<void> _checkFollowStatus() async {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user != null) {
      final repo = ref.read(wallpaperRepositoryProvider);
      final following = await repo.isFollowing(
        creatorUid: widget.wallpaper.uploaderId,
        followerUid: user.uid,
      );
      if (mounted) setState(() => _isFollowing = following);
    }
  }

  Future<void> _initVideoPlayer(String url) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      await _videoController!.play();
      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    if (_videoController != null && _isVideoInitialized) {
      setState(() {
        _isMuted = !_isMuted;
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      });
    }
  }

  Future<void> _toggleFollow() async {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    final repo = ref.read(wallpaperRepositoryProvider);
    final nextState = !_isFollowing;
    setState(() => _isFollowing = nextState);

    await repo.toggleFollow(
      creatorUid: widget.wallpaper.uploaderId,
      followerUid: user.uid,
      isCurrentlyFollowing: !nextState,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: DarkNeonTheme.cardSurface,
          content: Text(
            nextState ? 'Following ${widget.wallpaper.uploaderName}' : 'Unfollowed creator',
            style: TextStyle(color: nextState ? DarkNeonTheme.creatorAccent : Colors.white70),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _applyWallpaper() async {
    if (_isApplying) return;

    if (widget.wallpaper.type == WallpaperType.STATIC) {
      if (Platform.isIOS) {
        setState(() => _isApplying = true);
        try {
          await WallpaperChannelService.setStaticWallpaper(imageUrl: widget.wallpaper.imageUrl);
          if (mounted) {
            IosInstructionalModal.show(context);
          }
        } finally {
          if (mounted) setState(() => _isApplying = false);
        }
      } else {
        _showAndroidTargetPicker();
      }
    } else if (widget.wallpaper.type == WallpaperType.LIVE) {
      setState(() => _isApplying = true);
      try {
        final success = await WallpaperChannelService.setVideoWallpaper(
          videoUrl: widget.wallpaper.videoUrl ?? '',
        );
        if (mounted) {
          _showResultBanner(success ? 'Live Wallpaper service launched' : 'Launched Live Wallpaper chooser');
        }
      } finally {
        if (mounted) setState(() => _isApplying = false);
      }
    } else if (widget.wallpaper.type == WallpaperType.GYRO) {
      setState(() => _isApplying = true);
      try {
        final success = await WallpaperChannelService.setGyroWallpaper(
          backgroundUrl: widget.wallpaper.backgroundUrl ?? widget.wallpaper.imageUrl,
          foregroundUrl: widget.wallpaper.foregroundUrl ?? widget.wallpaper.thumbnailUrl,
        );
        if (mounted) {
          _showResultBanner(success ? '3D Gyro Service active in chooser' : 'Gyroscope wallpaper applied');
        }
      } finally {
        if (mounted) setState(() => _isApplying = false);
      }
    }
  }

  void _showAndroidTargetPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LiquidGlassContainer(
            borderRadius: 24,
            borderColor: DarkNeonTheme.primaryNeon,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'APPLY TO SCREEN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: DarkNeonTheme.primaryNeon,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 18),
                _buildTargetOption(
                  title: 'Home Screen',
                  icon: Icons.home_rounded,
                  target: WallpaperTargetScreen.HOME,
                ),
                const SizedBox(height: 10),
                _buildTargetOption(
                  title: 'Lock Screen',
                  icon: Icons.lock_outline_rounded,
                  target: WallpaperTargetScreen.LOCK,
                ),
                const SizedBox(height: 10),
                _buildTargetOption(
                  title: 'Both Screens',
                  icon: Icons.phone_android_rounded,
                  target: WallpaperTargetScreen.BOTH,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetOption({
    required String title,
    required IconData icon,
    required WallpaperTargetScreen target,
  }) {
    return BouncyTapWrapper(
      onTap: () async {
        Navigator.of(context).pop();
        setState(() => _isApplying = true);
        try {
          final res = await WallpaperChannelService.setStaticWallpaper(
            imageUrl: widget.wallpaper.imageUrl,
            target: target,
          );
          if (mounted) {
            _showResultBanner(res == 'APPLIED_ANDROID' ? 'Wallpaper set successfully!' : 'Wallpaper downloaded');
          }
        } finally {
          if (mounted) setState(() => _isApplying = false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: DarkNeonTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: DarkNeonTheme.primaryNeon, size: 22),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }

  void _showResultBanner(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: DarkNeonTheme.cardSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DarkNeonTheme.creatorAccent, width: 1.2),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: DarkNeonTheme.creatorAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Wallpaper Engine Render Layer
          _buildEngineViewer(),

          // 2. Top Header Controls (Back, Type Badge, Sound Toggle)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    BouncyTapWrapper(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const Spacer(),
                    if (widget.wallpaper.type == WallpaperType.LIVE) ...[
                      BouncyTapWrapper(
                        onTap: _toggleMute,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: DarkNeonTheme.secondaryNeon.withOpacity(0.5)),
                          ),
                          child: Icon(
                            _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            color: DarkNeonTheme.secondaryNeon,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    BouncyTapWrapper(
                      onTap: () => setState(() => _showInfoSheet = !_showInfoSheet),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Icon(
                          _showInfoSheet ? Icons.info : Icons.info_outline,
                          color: DarkNeonTheme.primaryNeon,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Bottom Controls: Creator, Rating, Apply Button
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info sheet expandable
                  if (_showInfoSheet) ...[
                    LiquidGlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.wallpaper.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: widget.wallpaper.tags.map((t) {
                              return Chip(
                                label: Text('#$t', style: const TextStyle(fontSize: 11, color: DarkNeonTheme.primaryNeon)),
                                backgroundColor: Colors.white.withOpacity(0.08),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action Bar Container
                  LiquidGlassContainer(
                    borderRadius: 28,
                    borderColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Creator Info & Follow
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.wallpaper.uploaderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  BouncyTapWrapper(
                                    onTap: _toggleFollow,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _isFollowing
                                            ? DarkNeonTheme.creatorAccent.withOpacity(0.2)
                                            : Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _isFollowing ? DarkNeonTheme.creatorAccent : Colors.white24,
                                        ),
                                      ),
                                      child: Text(
                                        _isFollowing ? 'FOLLOWING' : '+ FOLLOW',
                                        style: TextStyle(
                                          color: _isFollowing ? DarkNeonTheme.creatorAccent : Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Star Rating Button
                                  BouncyTapWrapper(
                                    onTap: () {
                                      RatingDialog.show(
                                        context,
                                        wallpaperTitle: widget.wallpaper.title,
                                        onRatingSubmitted: (rating) {
                                          final user = ref.read(currentUserProvider).asData?.value;
                                          if (user != null) {
                                            ref.read(wallpaperRepositoryProvider).rateWallpaper(
                                                  wallpaperId: widget.wallpaper.id,
                                                  creatorUid: widget.wallpaper.uploaderId,
                                                  userUid: user.uid,
                                                  rating: rating,
                                                );
                                            _showResultBanner('Thank you for rating $rating stars!');
                                          }
                                        },
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                        const SizedBox(width: 3),
                                        Text(
                                          widget.wallpaper.averageRating.toStringAsFixed(1),
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Apply Button
                        NeonButton(
                          text: widget.wallpaper.type == WallpaperType.GYRO
                              ? 'SET 3D GYRO'
                              : (widget.wallpaper.type == WallpaperType.LIVE ? 'SET LIVE' : 'APPLY'),
                          isFilled: true,
                          isLoading: _isApplying,
                          height: 46,
                          neonColor: widget.wallpaper.type == WallpaperType.GYRO
                              ? DarkNeonTheme.primaryNeon
                              : (widget.wallpaper.type == WallpaperType.LIVE
                                  ? DarkNeonTheme.secondaryNeon
                                  : DarkNeonTheme.creatorAccent),
                          icon: Icons.wallpaper_rounded,
                          onPressed: _applyWallpaper,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineViewer() {
    switch (widget.wallpaper.type) {
      case WallpaperType.GYRO:
        return GyroPreviewWidget(
          backgroundUrl: widget.wallpaper.backgroundUrl ?? widget.wallpaper.imageUrl,
          foregroundUrl: widget.wallpaper.foregroundUrl ?? widget.wallpaper.thumbnailUrl,
        );

      case WallpaperType.LIVE:
        if (_videoController != null && _isVideoInitialized) {
          return Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          );
        }
        return CachedNetworkImage(
          imageUrl: widget.wallpaper.imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(color: DarkNeonTheme.secondaryNeon),
          ),
        );

      case WallpaperType.STATIC:
        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.5,
          child: CachedNetworkImage(
            imageUrl: widget.wallpaper.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(
              child: CachedNetworkImage(
                imageUrl: widget.wallpaper.thumbnailUrl,
                fit: BoxFit.cover,
              ),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.white30, size: 64),
            ),
          ),
        );
    }
  }
}
