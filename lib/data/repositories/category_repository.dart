import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/api_constants.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final FirebaseFirestore? _customFirestore;

  CategoryRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  // Default curated categories with dark neon aesthetics
  static const List<CategoryModel> defaultCategories = [
    CategoryModel(
      id: 'all',
      name: 'Explore All',
      thumbnailUrl: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=300&q=80',
      sortOrder: 0,
      isActive: true,
    ),
    CategoryModel(
      id: 'cyberpunk',
      name: 'Cyberpunk',
      thumbnailUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=300&q=80',
      sortOrder: 1,
      isActive: true,
    ),
    CategoryModel(
      id: 'anime',
      name: 'Anime Neon',
      thumbnailUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=300&q=80',
      sortOrder: 2,
      isActive: true,
    ),
    CategoryModel(
      id: 'amoled',
      name: 'Dark AMOLED',
      thumbnailUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?auto=format&fit=crop&w=300&q=80',
      sortOrder: 3,
      isActive: true,
    ),
    CategoryModel(
      id: 'liquid',
      name: 'Liquid Glass',
      thumbnailUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=300&q=80',
      sortOrder: 4,
      isActive: true,
    ),
    CategoryModel(
      id: 'space',
      name: 'Deep Cosmos',
      thumbnailUrl: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=300&q=80',
      sortOrder: 5,
      isActive: true,
    ),
    CategoryModel(
      id: 'synthwave',
      name: 'Synthwave 80s',
      thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=300&q=80',
      sortOrder: 6,
      isActive: true,
    ),
  ];

  static List<CategoryModel>? _cachedCategories;

  Future<List<CategoryModel>> getCategories() async {
    if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
      return _cachedCategories!;
    }
    try {
      final db = _firestore;
      if (db != null) {
        final snapshot = await db
            .collection(ApiConstants.colCategories)
            .where('is_active', isEqualTo: true)
            .get()
            .timeout(const Duration(seconds: 2));

        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
          list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          _cachedCategories = [defaultCategories.first, ...list];
          return _cachedCategories!;
        }
      }
    } catch (_) {}
    _cachedCategories = defaultCategories;
    return defaultCategories;
  }
}
