import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/wallpaper_model.dart';

class CachedResponse {
  final DateTime timestamp;
  final Map<String, dynamic> data;

  CachedResponse({required this.timestamp, required this.data});

  bool get isValid => DateTime.now().difference(timestamp) < ApiConstants.pixabayCacheDuration;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };

  factory CachedResponse.fromJson(Map<String, dynamic> json) {
    return CachedResponse(
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}

class PixabayApiService {
  final Dio _dio;
  final String _apiKey;
  // Local cache mapped by cacheKey -> CachedResponse (complies with 24h Pixabay caching term)
  static final Map<String, CachedResponse> _memoryCache = {};

  PixabayApiService({Dio? dio, String? apiKey})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 5),
        )),
        _apiKey = apiKey ?? ApiConstants.defaultPixabayApiKey;

  String _buildCacheKey(String endpoint, Map<String, dynamic> params) {
    final sortedParams = params.keys.toList()..sort();
    final paramString = sortedParams.map((k) => '$k=${params[k]}').join('&');
    return '$endpoint?$paramString';
  }

  Future<List<WallpaperModel>> fetchImages({
    String query = 'neon cyberpunk',
    String? category,
    int page = 1,
    int perPage = 30,
  }) async {
    final params = {
      'key': _apiKey,
      'q': query.isEmpty ? 'neon wallpaper' : query,
      'image_type': 'photo',
      'orientation': 'vertical',
      'safesearch': 'true',
      'page': page,
      'per_page': perPage,
      if (category != null && category.isNotEmpty && category != 'all') 'category': category,
    };

    final cacheKey = _buildCacheKey('images', params);
    if (_memoryCache.containsKey(cacheKey) && _memoryCache[cacheKey]!.isValid) {
      final cachedHits = _memoryCache[cacheKey]!.data['hits'] as List<dynamic>? ?? [];
      return cachedHits.map((h) => WallpaperModel.fromPixabayImage(h, categoryId: category ?? 'all')).toList();
    }

    try {
      final response = await _dio.get(ApiConstants.pixabayBaseUrl, queryParameters: params);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        _memoryCache[cacheKey] = CachedResponse(timestamp: DateTime.now(), data: data);
        final hits = data['hits'] as List<dynamic>? ?? [];
        return hits.map((h) => WallpaperModel.fromPixabayImage(h, categoryId: category ?? 'all')).toList();
      }
    } catch (e) {
      // If network fails, check expired cache or fallback
      if (_memoryCache.containsKey(cacheKey)) {
        final fallbackHits = _memoryCache[cacheKey]!.data['hits'] as List<dynamic>? ?? [];
        return fallbackHits.map((h) => WallpaperModel.fromPixabayImage(h, categoryId: category ?? 'all')).toList();
      }
    }
    return _getCuratedFallbackImages(category ?? 'all');
  }

  Future<List<WallpaperModel>> fetchVideos({
    String query = 'motion neon',
    String? category,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = {
      'key': _apiKey,
      'q': query.isEmpty ? 'motion background' : query,
      'video_type': 'all',
      'safesearch': 'true',
      'page': page,
      'per_page': perPage,
      if (category != null && category.isNotEmpty && category != 'all') 'category': category,
    };

    final cacheKey = _buildCacheKey('videos', params);
    if (_memoryCache.containsKey(cacheKey) && _memoryCache[cacheKey]!.isValid) {
      final cachedHits = _memoryCache[cacheKey]!.data['hits'] as List<dynamic>? ?? [];
      return cachedHits.map((h) => WallpaperModel.fromPixabayVideo(h, categoryId: category ?? 'all')).toList();
    }

    try {
      final response = await _dio.get(ApiConstants.pixabayVideosUrl, queryParameters: params);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        _memoryCache[cacheKey] = CachedResponse(timestamp: DateTime.now(), data: data);
        final hits = data['hits'] as List<dynamic>? ?? [];
        return hits.map((h) => WallpaperModel.fromPixabayVideo(h, categoryId: category ?? 'all')).toList();
      }
    } catch (e) {
      if (_memoryCache.containsKey(cacheKey)) {
        final fallbackHits = _memoryCache[cacheKey]!.data['hits'] as List<dynamic>? ?? [];
        return fallbackHits.map((h) => WallpaperModel.fromPixabayVideo(h, categoryId: category ?? 'all')).toList();
      }
    }
    return _getCuratedFallbackVideos(category ?? 'all');
  }

  List<WallpaperModel> _getCuratedFallbackImages(String category) {
    return [
      WallpaperModel(
        id: 'curated_1',
        uploaderId: 'curated_cyber',
        uploaderName: 'CyberPulse',
        type: WallpaperType.STATIC,
        categoryId: category,
        title: 'NEON MATRIX TOKYO',
        tags: ['tokyo', 'cyberpunk', 'neon', 'rain'],
        imageUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=1200&q=80',
        thumbnailUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=400&q=80',
        averageRating: 4.95,
        ratingCount: 312,
        uploadedAt: DateTime.now(),
        source: 'CURATED',
      ),
      WallpaperModel(
        id: 'curated_2',
        uploaderId: 'curated_synth',
        uploaderName: 'SynthNova',
        type: WallpaperType.STATIC,
        categoryId: category,
        title: 'VAPOR HORIZON',
        tags: ['synthwave', 'grid', 'sunset', 'retro'],
        imageUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?auto=format&fit=crop&w=1200&q=80',
        thumbnailUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?auto=format&fit=crop&w=400&q=80',
        averageRating: 4.88,
        ratingCount: 204,
        uploadedAt: DateTime.now(),
        source: 'CURATED',
      ),
      WallpaperModel(
        id: 'curated_3',
        uploaderId: 'curated_dark',
        uploaderName: 'DarkGlass',
        type: WallpaperType.STATIC,
        categoryId: category,
        title: 'CRYSTAL AURORA',
        tags: ['aurora', 'liquid', 'glass', 'night'],
        imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1200&q=80',
        thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=400&q=80',
        averageRating: 4.92,
        ratingCount: 180,
        uploadedAt: DateTime.now(),
        source: 'CURATED',
      ),
    ];
  }

  List<WallpaperModel> _getCuratedFallbackVideos(String category) {
    return [
      WallpaperModel(
        id: 'curated_live_1',
        uploaderId: 'curated_motion',
        uploaderName: 'LiquidCinema',
        type: WallpaperType.LIVE,
        categoryId: category,
        title: 'NEON TUNNEL VORTEX',
        tags: ['loop', 'tunnel', 'neon', 'live'],
        imageUrl: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=400&q=80',
        thumbnailUrl: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=400&q=80',
        videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-tunnel-of-futuristic-neon-lights-seamless-loop-41584-large.mp4',
        averageRating: 4.96,
        ratingCount: 410,
        uploadedAt: DateTime.now(),
        source: 'CURATED',
      ),
    ];
  }
}
