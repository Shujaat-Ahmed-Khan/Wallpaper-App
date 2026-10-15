import 'package:cloud_firestore/cloud_firestore.dart';

enum WallpaperType {
  STATIC,
  LIVE,
  GYRO,
}

enum WallpaperStatus {
  PENDING,
  APPROVED,
  REJECTED,
}

class WallpaperModel {
  final String id;
  final String uploaderId;
  final String uploaderName;
  final WallpaperType type;
  final String categoryId;
  final String title;
  final List<String> tags;
  final String imageUrl;
  final String thumbnailUrl;
  final String? videoUrl;
  final String? backgroundUrl;
  final String? foregroundUrl;
  final WallpaperStatus status;
  final String? rejectionReason;
  final double averageRating;
  final int ratingCount;
  final DateTime uploadedAt;
  final String source; // 'FIREBASE' or 'PIXABAY'

  const WallpaperModel({
    required this.id,
    required this.uploaderId,
    required this.uploaderName,
    required this.type,
    required this.categoryId,
    required this.title,
    required this.tags,
    required this.imageUrl,
    required this.thumbnailUrl,
    this.videoUrl,
    this.backgroundUrl,
    this.foregroundUrl,
    this.status = WallpaperStatus.APPROVED,
    this.rejectionReason,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    required this.uploadedAt,
    this.source = 'FIREBASE',
  });

  factory WallpaperModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WallpaperModel.fromMap(data, id: doc.id);
  }

  factory WallpaperModel.fromMap(Map<String, dynamic> data, {String? id}) {
    WallpaperType type = WallpaperType.STATIC;
    final typeStr = data['type']?.toString().toUpperCase() ?? 'STATIC';
    if (typeStr == 'LIVE') type = WallpaperType.LIVE;
    if (typeStr == 'GYRO') type = WallpaperType.GYRO;

    WallpaperStatus status = WallpaperStatus.APPROVED;
    final statusStr = data['status']?.toString().toUpperCase() ?? 'APPROVED';
    if (statusStr == 'PENDING') status = WallpaperStatus.PENDING;
    if (statusStr == 'REJECTED') status = WallpaperStatus.REJECTED;

    DateTime uploadedAt = DateTime.now();
    if (data['uploaded_at'] is Timestamp) {
      uploadedAt = (data['uploaded_at'] as Timestamp).toDate();
    } else if (data['uploaded_at'] is String) {
      uploadedAt = DateTime.tryParse(data['uploaded_at']) ?? DateTime.now();
    }

    final rawTags = data['tags'];
    List<String> tagsList = [];
    if (rawTags is List) {
      tagsList = rawTags.map((e) => e.toString()).toList();
    }

    final imgUrl = data['image_url'] ?? data['largeImageURL'] ?? '';
    final thumbUrl = data['thumbnail_url'] ?? data['webformatURL'] ?? imgUrl;

    return WallpaperModel(
      id: id ?? data['id'] ?? '',
      uploaderId: data['uploader_id'] ?? 'community',
      uploaderName: data['uploader_name'] ?? 'Creator',
      type: type,
      categoryId: data['category_id'] ?? 'all',
      title: data['title'] ?? 'Neon Wallpaper',
      tags: tagsList,
      imageUrl: imgUrl,
      thumbnailUrl: thumbUrl.isNotEmpty ? thumbUrl : imgUrl,
      videoUrl: data['video_url'],
      backgroundUrl: data['background_url'],
      foregroundUrl: data['foreground_url'],
      status: status,
      rejectionReason: data['rejection_reason'] ?? data['rejectionReason'],
      averageRating: (data['average_rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (data['rating_count'] as num?)?.toInt() ?? 0,
      uploadedAt: uploadedAt,
      source: data['source'] ?? 'FIREBASE',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uploader_id': uploaderId,
      'uploader_name': uploaderName,
      'type': type.name,
      'category_id': categoryId,
      'title': title,
      'tags': tags,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'video_url': videoUrl,
      'background_url': backgroundUrl,
      'foreground_url': foregroundUrl,
      'status': status.name,
      'rejection_reason': rejectionReason,
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'uploaded_at': Timestamp.fromDate(uploadedAt),
      'source': source,
    };
  }

  WallpaperModel copyWith({
    String? id,
    String? uploaderId,
    String? uploaderName,
    WallpaperType? type,
    String? categoryId,
    String? title,
    List<String>? tags,
    String? imageUrl,
    String? thumbnailUrl,
    String? videoUrl,
    String? backgroundUrl,
    String? foregroundUrl,
    WallpaperStatus? status,
    String? rejectionReason,
    double? averageRating,
    int? ratingCount,
    DateTime? uploadedAt,
    String? source,
  }) {
    return WallpaperModel(
      id: id ?? this.id,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      foregroundUrl: foregroundUrl ?? this.foregroundUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      source: source ?? this.source,
    );
  }

  factory WallpaperModel.fromPixabayImage(Map<String, dynamic> hit, {String categoryId = 'nature'}) {
    final tagsStr = hit['tags']?.toString() ?? '';
    final tagsList = tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final id = 'pixabay_img_${hit['id']}';
    final user = hit['user']?.toString() ?? 'Pixabay Artist';
    final largeImage = hit['largeImageURL'] ?? hit['webformatURL'] ?? '';
    final webFormat = hit['webformatURL'] ?? largeImage;

    return WallpaperModel(
      id: id,
      uploaderId: 'pixabay_${hit['user_id'] ?? 0}',
      uploaderName: user,
      type: WallpaperType.STATIC,
      categoryId: categoryId,
      title: tagsList.isNotEmpty ? tagsList.first.toUpperCase() : 'Pixabay Art',
      tags: tagsList,
      imageUrl: largeImage,
      thumbnailUrl: webFormat,
      status: WallpaperStatus.APPROVED,
      averageRating: ((hit['likes'] as num?)?.toDouble() ?? 100) > 500 ? 4.9 : 4.7,
      ratingCount: (hit['views'] as num?)?.toInt() ?? 42,
      uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
      source: 'PIXABAY',
    );
  }

  factory WallpaperModel.fromPixabayVideo(Map<String, dynamic> hit, {String categoryId = 'nature'}) {
    final tagsStr = hit['tags']?.toString() ?? '';
    final tagsList = tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final id = 'pixabay_vid_${hit['id']}';
    final user = hit['user']?.toString() ?? 'Pixabay Video';

    // Pixabay videos object contains medium / large / tiny
    final videos = hit['videos'] as Map<String, dynamic>? ?? {};
    final largeVideo = videos['large']?['url'] ?? videos['medium']?['url'] ?? videos['small']?['url'] ?? '';
    final thumb = hit['picture_id'] != null
        ? 'https://i.vimeocdn.com/video/${hit['picture_id']}_640x360.jpg'
        : (videos['tiny']?['url'] ?? '');

    return WallpaperModel(
      id: id,
      uploaderId: 'pixabay_${hit['user_id'] ?? 0}',
      uploaderName: user,
      type: WallpaperType.LIVE,
      categoryId: categoryId,
      title: tagsList.isNotEmpty ? tagsList.first.toUpperCase() : 'Live Motion Art',
      tags: tagsList,
      imageUrl: thumb,
      thumbnailUrl: thumb,
      videoUrl: largeVideo,
      status: WallpaperStatus.APPROVED,
      averageRating: 4.8,
      ratingCount: (hit['views'] as num?)?.toInt() ?? 88,
      uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
      source: 'PIXABAY',
    );
  }
}
