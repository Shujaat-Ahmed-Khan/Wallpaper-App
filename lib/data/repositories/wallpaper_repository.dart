import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/api_constants.dart';
import '../models/wallpaper_model.dart';
import '../services/pixabay_api_service.dart';

class WallpaperRepository {
  final FirebaseFirestore? _customFirestore;
  final PixabayApiService _pixabayService;

  // In-memory submissions fallback if Firestore is offline
  static final List<WallpaperModel> _localSubmissions = [];

  WallpaperRepository({
    FirebaseFirestore? firestore,
    PixabayApiService? pixabayService,
  })  : _customFirestore = firestore,
        _pixabayService = pixabayService ?? PixabayApiService();

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  // Curated 3D Gyroscopic Wallpapers (Multi-layer Parallax)
  static final List<WallpaperModel> curatedGyroWallpapers = [
    WallpaperModel(
      id: 'gyro_cyber_ronin',
      uploaderId: 'bitrops_master',
      uploaderName: 'CyberRonin 3D',
      type: WallpaperType.GYRO,
      categoryId: 'cyberpunk',
      title: 'CYBER RONIN 3D PARALLAX',
      tags: ['gyro', 'parallax', 'cyberpunk', 'ronin', 'neon'],
      imageUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=1200&q=80',
      thumbnailUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=400&q=80',
      backgroundUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1200&q=80',
      foregroundUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/6.png',
      averageRating: 4.98,
      ratingCount: 520,
      uploadedAt: DateTime.now().subtract(const Duration(hours: 5)),
      source: 'CURATED_GYRO',
    ),
    WallpaperModel(
      id: 'gyro_neon_sphere',
      uploaderId: 'bitrops_master',
      uploaderName: 'QuantumVisions',
      type: WallpaperType.GYRO,
      categoryId: 'liquid',
      title: 'QUANTUM SPHERE 3D',
      tags: ['gyro', '3d', 'sphere', 'liquid', 'cyan'],
      imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1200&q=80',
      thumbnailUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=400&q=80',
      backgroundUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?auto=format&fit=crop&w=1200&q=80',
      foregroundUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/150.png',
      averageRating: 4.94,
      ratingCount: 388,
      uploadedAt: DateTime.now().subtract(const Duration(hours: 12)),
      source: 'CURATED_GYRO',
    ),
  ];

  // Curated 4K Static Wallpapers
  static final List<WallpaperModel> curatedStaticWallpapers = [
    WallpaperModel(
      id: 'static_tokyo_cyber',
      uploaderId: 'bitrops_master',
      uploaderName: 'NeonArchitect',
      type: WallpaperType.STATIC,
      categoryId: 'cyberpunk',
      title: 'NEON SHINJUKU 2077',
      tags: ['cyberpunk', 'tokyo', 'neon', 'amoled', 'city'],
      imageUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=1200&q=80',
      thumbnailUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=400&q=80',
      averageRating: 4.96,
      ratingCount: 840,
      uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
      source: 'CURATED',
    ),
    WallpaperModel(
      id: 'static_liquid_prism',
      uploaderId: 'bitrops_master',
      uploaderName: 'ChromaFlow',
      type: WallpaperType.STATIC,
      categoryId: 'liquid',
      title: 'CHROMATIC LIQUID GLASS',
      tags: ['liquid', 'glass', 'prism', 'neon', 'abstract'],
      imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1200&q=80',
      thumbnailUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=400&q=80',
      averageRating: 4.89,
      ratingCount: 620,
      uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
      source: 'CURATED',
    ),
    WallpaperModel(
      id: 'static_deep_space_nebula',
      uploaderId: 'bitrops_master',
      uploaderName: 'AstroVisuals',
      type: WallpaperType.STATIC,
      categoryId: 'space',
      title: 'STELLAR NEON NEBULA',
      tags: ['space', 'galaxy', 'amoled', 'purple', 'stars'],
      imageUrl: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=1200&q=80',
      thumbnailUrl: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=400&q=80',
      averageRating: 4.95,
      ratingCount: 1102,
      uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
      source: 'CURATED',
    ),
    WallpaperModel(
      id: 'static_anime_neon_girl',
      uploaderId: 'bitrops_master',
      uploaderName: 'OtakuCyber',
      type: WallpaperType.STATIC,
      categoryId: 'anime',
      title: 'AKIRA HIGHWAYS',
      tags: ['anime', 'neon', 'cyber', 'retro', '4k'],
      imageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=1200&q=80',
      thumbnailUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=400&q=80',
      averageRating: 4.92,
      ratingCount: 745,
      uploadedAt: DateTime.now().subtract(const Duration(days: 4)),
      source: 'CURATED',
    ),
    WallpaperModel(
      id: 'static_amoled_geometric',
      uploaderId: 'bitrops_master',
      uploaderName: 'VektorStudio',
      type: WallpaperType.STATIC,
      categoryId: 'amoled',
      title: 'DARK MATRIX HORIZON',
      tags: ['amoled', 'minimal', 'dark', 'geometry', 'glow'],
      imageUrl: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=1200&q=80',
      thumbnailUrl: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=400&q=80',
      averageRating: 4.91,
      ratingCount: 530,
      uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
      source: 'CURATED',
    ),
  ];

  // Curated 60FPS Looping Live Wallpapers
  static final List<WallpaperModel> curatedLiveWallpapers = [
    WallpaperModel(
      id: 'live_neon_speedway',
      uploaderId: 'bitrops_master',
      uploaderName: 'SynthMotion',
      type: WallpaperType.LIVE,
      categoryId: 'cyberpunk',
      title: 'SYNTHWAVE NEON HIGHWAY',
      tags: ['live', 'motion', 'loop', 'speedway', 'neon'],
      imageUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?auto=format&fit=crop&w=1200&q=80',
      thumbnailUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?auto=format&fit=crop&w=400&q=80',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-tunnel-of-futuristic-neon-lights-seamless-loop-41584-large.mp4',
      averageRating: 4.99,
      ratingCount: 1420,
      uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
      source: 'CURATED',
    ),
    WallpaperModel(
      id: 'live_quantum_loop',
      uploaderId: 'bitrops_master',
      uploaderName: 'HypnoVibe',
      type: WallpaperType.LIVE,
      categoryId: 'liquid',
      title: 'QUANTUM CHROMA FLOW',
      tags: ['live', 'liquid', 'fluid', 'chroma', 'loop'],
      imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1200&q=80',
      thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=400&q=80',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-top-view-of-fluid-motion-with-neon-lights-42999-large.mp4',
      averageRating: 4.93,
      ratingCount: 680,
      uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
      source: 'CURATED',
    ),
  ];

  // In-memory cache for instant feed switching
  static final Map<String, List<WallpaperModel>> _wallpapersCache = {};

  Future<List<WallpaperModel>> getWallpapers({
    String? categoryId,
    WallpaperType? type,
    String? searchQuery,
    int page = 1,
  }) async {
    final cacheKey = '${categoryId ?? "all"}_${type?.name ?? "all"}_${searchQuery ?? ""}_$page';
    if (_wallpapersCache.containsKey(cacheKey) && _wallpapersCache[cacheKey]!.isNotEmpty) {
      return _wallpapersCache[cacheKey]!;
    }

    final List<WallpaperModel> results = [];

    // 1. Instantly populate curated & local wallpapers (0ms delay)
    if (type == null || type == WallpaperType.GYRO) {
      if (categoryId == null || categoryId == 'all' || categoryId == 'cyberpunk' || categoryId == 'liquid') {
        results.addAll(curatedGyroWallpapers);
      }
    }

    if (type == null || type == WallpaperType.STATIC) {
      results.addAll(curatedStaticWallpapers.where((w) {
        if (categoryId != null && categoryId != 'all') return w.categoryId == categoryId;
        return true;
      }));
    }

    if (type == null || type == WallpaperType.LIVE) {
      results.addAll(curatedLiveWallpapers.where((w) {
        if (categoryId != null && categoryId != 'all') return w.categoryId == categoryId;
        return true;
      }));
    }

    for (var sub in _localSubmissions) {
      if (sub.status == WallpaperStatus.APPROVED) {
        if (categoryId == null || categoryId == 'all' || sub.categoryId == categoryId) {
          if (type == null || sub.type == type) {
            results.add(sub);
          }
        }
      }
    }

    // 2. Parallel remote fetch with tight timeouts
    final Future<List<WallpaperModel>> firestoreFuture = () async {
      try {
        final db = _firestore;
        if (db == null) return <WallpaperModel>[];
        Query query = db
            .collection(ApiConstants.colWallpapers)
            .where('status', isEqualTo: 'APPROVED');
        if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
          query = query.where('category_id', isEqualTo: categoryId);
        }
        if (type != null) {
          query = query.where('type', isEqualTo: type.name);
        }
        final snapshot = await query.limit(20).get().timeout(const Duration(seconds: 3));
        return snapshot.docs.map((doc) => WallpaperModel.fromFirestore(doc)).toList();
      } catch (_) {
        return <WallpaperModel>[];
      }
    }();

    final Future<List<WallpaperModel>> pixabayImagesFuture = () async {
      if (type != null && type != WallpaperType.STATIC) return <WallpaperModel>[];
      try {
        final queryText = searchQuery?.isNotEmpty == true
            ? searchQuery!
            : (categoryId != null && categoryId != 'all' ? '$categoryId neon' : 'neon cyberpunk 4k');
        return await _pixabayService.fetchImages(
          query: queryText,
          category: (categoryId != 'all' && categoryId != null) ? categoryId : null,
          page: page,
          perPage: 20,
        ).timeout(const Duration(seconds: 4));
      } catch (_) {
        return <WallpaperModel>[];
      }
    }();

    final Future<List<WallpaperModel>> pixabayVideosFuture = () async {
      if (type != null && type != WallpaperType.LIVE) return <WallpaperModel>[];
      try {
        final queryText = searchQuery?.isNotEmpty == true ? searchQuery! : 'neon motion loop';
        return await _pixabayService.fetchVideos(
          query: queryText,
          page: page,
          perPage: 12,
        ).timeout(const Duration(seconds: 4));
      } catch (_) {
        return <WallpaperModel>[];
      }
    }();

    try {
      final remoteLists = await Future.wait([firestoreFuture, pixabayImagesFuture, pixabayVideosFuture]);
      for (var list in remoteLists) {
        results.addAll(list);
      }
    } catch (_) {}

    // Deduplicate by ID
    final seen = <String>{};
    final unique = results.where((item) => seen.add(item.id)).toList();

    List<WallpaperModel> finalWallpapers = unique;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      finalWallpapers = unique.where((w) {
        return w.title.toLowerCase().contains(q) ||
            w.tags.any((t) => t.toLowerCase().contains(q)) ||
            w.uploaderName.toLowerCase().contains(q);
      }).toList();
    }

    if (finalWallpapers.isNotEmpty) {
      _wallpapersCache[cacheKey] = finalWallpapers;
    }

    return finalWallpapers;
  }

  Future<List<WallpaperModel>> getCreatorWallpapers(String uploaderId) async {
    final List<WallpaperModel> list = [];
    try {
      final db = _firestore;
      if (db != null) {
        final snapshot = await db
            .collection(ApiConstants.colWallpapers)
            .where('uploader_id', isEqualTo: uploaderId)
            .orderBy('uploaded_at', descending: true)
            .get();

        list.addAll(snapshot.docs.map((d) => WallpaperModel.fromFirestore(d)));
      }
    } catch (_) {}

    // Add local memory items
    final localMatches = _localSubmissions.where((w) => w.uploaderId == uploaderId);
    for (var m in localMatches) {
      if (!list.any((existing) => existing.id == m.id)) {
        list.add(m);
      }
    }
    return list;
  }

  Future<void> submitCreatorWallpaper(WallpaperModel wallpaper) async {
    _localSubmissions.insert(0, wallpaper);
    try {
      final db = _firestore;
      if (db != null) {
        final docRef = db.collection(ApiConstants.colWallpapers).doc();
        final toSave = wallpaper.toMap();
        toSave['id'] = docRef.id;
        toSave['status'] = 'PENDING';
        await docRef.set(toSave);
      }
    } catch (_) {}
  }

  Future<void> rateWallpaper({
    required String wallpaperId,
    required String creatorUid,
    required String userUid,
    required int rating,
  }) async {
    try {
      final db = _firestore;
      if (db != null) {
        final docId = '${wallpaperId}_$userUid';
        await db.collection(ApiConstants.colRatings).doc(docId).set({
          'wallpaper_id': wallpaperId,
          'creator_uid': creatorUid,
          'user_uid': userUid,
          'rating': rating,
          'rated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  Future<bool> isFollowing({
    required String creatorUid,
    required String followerUid,
  }) async {
    try {
      final db = _firestore;
      if (db != null) {
        final docId = '${creatorUid}_$followerUid';
        final doc = await db.collection(ApiConstants.colFollowers).doc(docId).get().timeout(const Duration(seconds: 2));
        return doc.exists;
      }
    } catch (_) {}
    return false;
  }

  Future<void> toggleFollow({
    required String creatorUid,
    required String followerUid,
    required bool isCurrentlyFollowing,
  }) async {
    try {
      final db = _firestore;
      if (db != null) {
        final docId = '${creatorUid}_$followerUid';
        final ref = db.collection(ApiConstants.colFollowers).doc(docId);
        if (isCurrentlyFollowing) {
          await ref.delete().timeout(const Duration(seconds: 2));
        } else {
          await ref.set({
            'creator_uid': creatorUid,
            'follower_uid': followerUid,
            'followed_at': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 2));
        }
      }
    } catch (_) {}
  }
}
