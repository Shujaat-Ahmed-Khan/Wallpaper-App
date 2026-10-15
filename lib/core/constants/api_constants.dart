class ApiConstants {
  // Pixabay Public/Demo Key (can be replaced by user or via remote config/env)
  // Pixabay allows public query with open key or custom key
  static const String defaultPixabayApiKey = '43425983-34e8979fcfa0026e6d1c8eb1a';
  static const String pixabayBaseUrl = 'https://pixabay.com/api/';
  static const String pixabayVideosUrl = 'https://pixabay.com/api/videos/';

  // Firestore Collection Names
  static const String colUsers = 'Users';
  static const String colCategories = 'Categories';
  static const String colWallpapers = 'Wallpapers';
  static const String colFollowers = 'Followers';
  static const String colRatings = 'Ratings';

  // Method Channels
  static const String gyroMethodChannel = 'com.bitrops.wallpaperapp/gyro';

  // Cache settings
  static const Duration pixabayCacheDuration = Duration(hours: 24);
}
