import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String thumbnailUrl;
  final int sortOrder;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.sortOrder = 1,
    this.isActive = true,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryModel.fromMap(data, id: doc.id);
  }

  factory CategoryModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return CategoryModel(
      id: id ?? data['id'] ?? '',
      name: data['name'] ?? '',
      thumbnailUrl: data['thumbnail_url'] ?? '',
      sortOrder: (data['sort_order'] as num?)?.toInt() ?? 1,
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'thumbnail_url': thumbnailUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}
