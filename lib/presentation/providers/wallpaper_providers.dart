import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/wallpaper_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/wallpaper_repository.dart';
import '../../data/repositories/category_repository.dart';

final wallpaperRepositoryProvider = Provider<WallpaperRepository>((ref) {
  return WallpaperRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';
  void setCategory(String id) => state = id;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

class SelectedTypeFilterNotifier extends Notifier<WallpaperType?> {
  @override
  WallpaperType? build() => null;
  void setType(WallpaperType? type) => state = type;
}

final selectedTypeFilterProvider =
    NotifierProvider<SelectedTypeFilterNotifier, WallpaperType?>(SelectedTypeFilterNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getCategories();
});

final wallpapersListProvider = FutureProvider<List<WallpaperModel>>((ref) async {
  final repo = ref.watch(wallpaperRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final type = ref.watch(selectedTypeFilterProvider);
  final query = ref.watch(searchQueryProvider);

  return repo.getWallpapers(
    categoryId: category,
    type: type,
    searchQuery: query,
  );
});

final creatorWallpapersProvider = FutureProvider.family<List<WallpaperModel>, String>((ref, uploaderId) async {
  final repo = ref.watch(wallpaperRepositoryProvider);
  return repo.getCreatorWallpapers(uploaderId);
});
