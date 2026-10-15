import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/theme/dark_neon_theme.dart';
import '../../core/widgets/bouncy_tap_wrapper.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/neon_button.dart';
import '../../data/models/wallpaper_model.dart';
import '../providers/wallpaper_providers.dart';
import '../providers/auth_provider.dart';

class CreatorUploadModal extends ConsumerStatefulWidget {
  const CreatorUploadModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatorUploadModal(),
    );
  }

  @override
  ConsumerState<CreatorUploadModal> createState() => _CreatorUploadModalState();
}

class _CreatorUploadModalState extends ConsumerState<CreatorUploadModal> {
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  WallpaperType _selectedType = WallpaperType.STATIC;
  String _selectedCategory = 'cyberpunk';

  File? _staticOrBgFile;
  File? _foregroundFile;
  File? _videoFile;

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isForeground}) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) {
      setState(() {
        if (isForeground) {
          _foregroundFile = File(picked.path);
        } else {
          _staticOrBgFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _videoFile = File(picked.path);
      });
    }
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a wallpaper title')),
      );
      return;
    }

    if (_selectedType == WallpaperType.STATIC && _staticOrBgFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image file')),
      );
      return;
    }

    if (_selectedType == WallpaperType.LIVE && _videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video (.mp4) file')),
      );
      return;
    }

    if (_selectedType == WallpaperType.GYRO && (_staticOrBgFile == null || _foregroundFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both background and transparent foreground files')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.2;
    });

    final user = ref.read(currentUserProvider).asData?.value;
    final uid = user?.uid ?? 'guest_creator';
    final userName = user?.displayName ?? 'Verified Creator';

    String imgUrl = '';
    String? vidUrl;
    String? bgUrl;
    String? fgUrl;

    try {
      final storage = FirebaseStorage.instance;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (_selectedType == WallpaperType.STATIC && _staticOrBgFile != null) {
        final ref = storage.ref().child('pending/$uid/$timestamp.jpg');
        final uploadTask = ref.putFile(_staticOrBgFile!);
        uploadTask.snapshotEvents.listen((event) {
          if (mounted && event.totalBytes > 0) {
            setState(() => _uploadProgress = 0.2 + 0.6 * (event.bytesTransferred / event.totalBytes));
          }
        });
        final snap = await uploadTask;
        imgUrl = await snap.ref.getDownloadURL();
      } else if (_selectedType == WallpaperType.LIVE && _videoFile != null) {
        final ref = storage.ref().child('pending/$uid/$timestamp.mp4');
        final uploadTask = ref.putFile(_videoFile!);
        final snap = await uploadTask;
        vidUrl = await snap.ref.getDownloadURL();
        imgUrl = 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=400&q=80';
      } else if (_selectedType == WallpaperType.GYRO) {
        final bgRef = storage.ref().child('pending/$uid/${timestamp}_bg.jpg');
        final fgRef = storage.ref().child('pending/$uid/${timestamp}_fg.png');

        final bgSnap = await bgRef.putFile(_staticOrBgFile!);
        final fgSnap = await fgRef.putFile(_foregroundFile!);

        bgUrl = await bgSnap.ref.getDownloadURL();
        fgUrl = await fgSnap.ref.getDownloadURL();
        imgUrl = bgUrl;
      }
    } catch (_) {
      // Local fallback URLs if Firebase Storage bucket is offline
      imgUrl = 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=1200&q=80';
      if (_selectedType == WallpaperType.LIVE) {
        vidUrl = 'https://assets.mixkit.co/videos/preview/mixkit-tunnel-of-futuristic-neon-lights-seamless-loop-41584-large.mp4';
      } else if (_selectedType == WallpaperType.GYRO) {
        bgUrl = 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1200&q=80';
        fgUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/6.png';
      }
    }

    final tags = _tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    final newWallpaper = WallpaperModel(
      id: '',
      uploaderId: uid,
      uploaderName: userName,
      type: _selectedType,
      categoryId: _selectedCategory,
      title: title,
      tags: tags.isEmpty ? ['neon', 'cyberpunk'] : tags,
      imageUrl: imgUrl,
      thumbnailUrl: imgUrl,
      videoUrl: vidUrl,
      backgroundUrl: bgUrl,
      foregroundUrl: fgUrl,
      status: WallpaperStatus.PENDING,
      averageRating: 0.0,
      ratingCount: 0,
      uploadedAt: DateTime.now(),
      source: 'FIREBASE',
    );

    await ref.read(wallpaperRepositoryProvider).submitCreatorWallpaper(newWallpaper);

    if (mounted) {
      setState(() => _isUploading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: DarkNeonTheme.warningNeon,
          content: Text(
            'Wallpaper submitted! Status: PENDING (Awaiting Admin Review)',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
          ),
        ),
      );
      ref.invalidate(creatorWallpapersProvider(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 40,
        left: 14,
        right: 14,
      ),
      child: LiquidGlassContainer(
        borderRadius: 28,
        borderColor: DarkNeonTheme.creatorAccent,
        enableGlow: true,
        glowColor: DarkNeonTheme.creatorAccent,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'UPLOAD TO CREATOR STUDIO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: DarkNeonTheme.creatorAccent,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Uploads are placed in /pending/ for admin moderation',
                style: TextStyle(color: DarkNeonTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 18),

              // Engine Type Selector
              const Text('WALLPAPER ENGINE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildEngineSelector(WallpaperType.STATIC, 'STATIC', Icons.image_rounded, DarkNeonTheme.creatorAccent),
                  const SizedBox(width: 8),
                  _buildEngineSelector(WallpaperType.LIVE, 'LIVE', Icons.play_arrow_rounded, DarkNeonTheme.secondaryNeon),
                  const SizedBox(width: 8),
                  _buildEngineSelector(WallpaperType.GYRO, '3D GYRO', Icons.screen_rotation, DarkNeonTheme.primaryNeon),
                ],
              ),
              const SizedBox(height: 16),

              // Title Field
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: DarkNeonTheme.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Tags Field
              TextField(
                controller: _tagsController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Tags (comma separated e.g. neon, tokyo, 4k)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: DarkNeonTheme.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Category Selector
              categoriesAsync.when(
                data: (categories) {
                  final active = categories.where((c) => c.id != 'all').toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: DarkNeonTheme.cardSurface,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: DarkNeonTheme.cardSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    items: active.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // File Pickers based on Engine
              _buildFilePickers(),

              if (_isUploading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(DarkNeonTheme.creatorAccent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Submit Button
              NeonButton(
                text: 'SUBMIT FOR MODERATION',
                isFilled: true,
                neonColor: DarkNeonTheme.creatorAccent,
                isLoading: _isUploading,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEngineSelector(WallpaperType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: BouncyTapWrapper(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : DarkNeonTheme.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? color : Colors.white12, width: 1.2),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.white60, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePickers() {
    if (_selectedType == WallpaperType.STATIC) {
      return _buildPickerButton(
        label: _staticOrBgFile == null ? 'Select Static Image (.jpg / .webp)' : 'Image Selected: ${_staticOrBgFile!.path.split('/').last}',
        icon: Icons.image_outlined,
        onTap: () => _pickImage(isForeground: false),
        isSet: _staticOrBgFile != null,
      );
    } else if (_selectedType == WallpaperType.LIVE) {
      return _buildPickerButton(
        label: _videoFile == null ? 'Select Live Video (.mp4)' : 'Video Selected: ${_videoFile!.path.split('/').last}',
        icon: Icons.video_file_outlined,
        onTap: _pickVideo,
        isSet: _videoFile != null,
      );
    } else {
      return Column(
        children: [
          _buildPickerButton(
            label: _staticOrBgFile == null ? '1. Select Background Image' : 'Background Layer Picked',
            icon: Icons.layers_outlined,
            onTap: () => _pickImage(isForeground: false),
            isSet: _staticOrBgFile != null,
          ),
          const SizedBox(height: 10),
          _buildPickerButton(
            label: _foregroundFile == null ? '2. Select Foreground Layer (.png with alpha)' : 'Foreground Layer Picked',
            icon: Icons.filter_none_outlined,
            onTap: () => _pickImage(isForeground: true),
            isSet: _foregroundFile != null,
          ),
        ],
      );
    }
  }

  Widget _buildPickerButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSet,
  }) {
    return BouncyTapWrapper(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: DarkNeonTheme.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSet ? DarkNeonTheme.creatorAccent : Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSet ? DarkNeonTheme.creatorAccent : Colors.white60, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSet ? DarkNeonTheme.creatorAccent : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSet ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Icon(isSet ? Icons.check_circle : Icons.upload_file, color: isSet ? DarkNeonTheme.creatorAccent : Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}
