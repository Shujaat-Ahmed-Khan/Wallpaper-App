import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import '../constants/api_constants.dart';

enum WallpaperTargetScreen {
  HOME,
  LOCK,
  BOTH,
}

class WallpaperChannelService {
  static const MethodChannel _channel = MethodChannel(ApiConstants.gyroMethodChannel);

  /// Applies a static wallpaper
  /// Returns: 'APPLIED_ANDROID' or 'SAVED_TO_PHOTOS_IOS'
  static Future<String> setStaticWallpaper({
    required String imageUrl,
    WallpaperTargetScreen target = WallpaperTargetScreen.BOTH,
  }) async {
    // 1. Download/retrieve cached image file
    final file = await DefaultCacheManager().getSingleFile(imageUrl);

    if (Platform.isIOS) {
      // iOS fallback: Save to Photos via Gal
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putImage(file.path);
      return 'SAVED_TO_PHOTOS_IOS';
    } else {
      // Android: Native WallpaperManager via MethodChannel
      final String targetStr = target.name;
      final bool success = await _channel.invokeMethod('setStaticWallpaper', {
        'imagePath': file.path,
        'target': targetStr,
      }) ?? false;

      return success ? 'APPLIED_ANDROID' : 'FAILED';
    }
  }

  /// Launches Live Video Wallpaper
  static Future<bool> setVideoWallpaper({
    required String videoUrl,
  }) async {
    if (Platform.isIOS) {
      // Live video wallpaper direct setting is not permitted on iOS sandboxed apps
      return false;
    }

    try {
      final bool success = await _channel.invokeMethod('setVideoWallpaper') ?? false;
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Sets Native 3D Gyroscopic Wallpaper Service
  static Future<bool> setGyroWallpaper({
    required String backgroundUrl,
    required String foregroundUrl,
  }) async {
    if (Platform.isIOS) {
      // Gyro system wallpaper is only supported on Android WallpaperService
      return false;
    }

    // Download both layers locally
    final bgFile = await DefaultCacheManager().getSingleFile(backgroundUrl);
    final fgFile = await DefaultCacheManager().getSingleFile(foregroundUrl);

    try {
      final bool success = await _channel.invokeMethod('setGyroWallpaper', {
        'backgroundPath': bgFile.path,
        'foregroundPath': fgFile.path,
      }) ?? false;
      return success;
    } catch (e) {
      return false;
    }
  }
}
