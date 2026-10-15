import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  final int totalFollowers;
  final int totalUploads;
  final double averageRating;
  final int ratingCount;

  const UserStats({
    this.totalFollowers = 0,
    this.totalUploads = 0,
    this.averageRating = 0.0,
    this.ratingCount = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const UserStats();
    return UserStats(
      totalFollowers: (data['total_followers'] as num?)?.toInt() ?? 0,
      totalUploads: (data['total_uploads'] as num?)?.toInt() ?? 0,
      averageRating: (data['average_rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (data['rating_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_followers': totalFollowers,
      'total_uploads': totalUploads,
      'average_rating': averageRating,
      'rating_count': ratingCount,
    };
  }
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final String role; // "USER" | "CREATOR" | "ADMIN"
  final UserStats stats;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.bio = '',
    this.avatarUrl = '',
    this.role = 'USER',
    this.stats = const UserStats(),
    required this.createdAt,
  });

  bool get isCreator => role == 'CREATOR' || role == 'ADMIN';
  bool get isAdmin => role == 'ADMIN';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, uid: doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, {String? uid}) {
    DateTime createdAt = DateTime.now();
    if (data['created_at'] is Timestamp) {
      createdAt = (data['created_at'] as Timestamp).toDate();
    } else if (data['created_at'] is String) {
      createdAt = DateTime.tryParse(data['created_at']) ?? DateTime.now();
    }

    return UserModel(
      uid: uid ?? data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['display_name'] ?? 'Cyber Explorer',
      bio: data['bio'] ?? '',
      avatarUrl: data['avatar_url'] ?? '',
      role: data['role'] ?? 'USER',
      stats: UserStats.fromMap(data['stats'] as Map<String, dynamic>?),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'role': role,
      'stats': stats.toMap(),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? role,
    UserStats? stats,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      stats: stats ?? this.stats,
      createdAt: createdAt,
    );
  }
}
