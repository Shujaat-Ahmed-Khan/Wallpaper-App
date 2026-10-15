package com.bitrops.wallpaper_app

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.bitrops.wallpaperapp/gyro"

    override fun getRenderMode(): RenderMode {
        // Crucial: Use Texture render mode so opening live wallpaper chooser does not crash or tear
        return RenderMode.texture
    }

    override fun shouldDestroyEngineWithHost(): Boolean {
        // Return false so launching native wallpaper preview intent does not kill the Dart isolate
        return false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setGyroWallpaper" -> {
                    val bgPath = call.argument<String>("backgroundPath")
                    val fgPath = call.argument<String>("foregroundPath")

                    if (bgPath == null || fgPath == null) {
                        result.error("INVALID_ARGS", "Background and foreground paths are required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val prefs = getSharedPreferences("neon_wallpaper_prefs", Context.MODE_PRIVATE)
                        prefs.edit()
                            .putString("background_path", bgPath)
                            .putString("foreground_path", fgPath)
                            .apply()

                        val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                            putExtra(
                                WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                                ComponentName(this@MainActivity, GyroWallpaperService::class.java)
                            )
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WALLPAPER_ERROR", e.localizedMessage, null)
                    }
                }

                "setStaticWallpaper" -> {
                    val imagePath = call.argument<String>("imagePath")
                    val screenTarget = call.argument<String>("target") ?: "BOTH" // "HOME", "LOCK", "BOTH"

                    if (imagePath == null || !File(imagePath).exists()) {
                        result.error("FILE_NOT_FOUND", "Wallpaper image path does not exist", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val wallpaperManager = WallpaperManager.getInstance(applicationContext)
                        val bitmap = BitmapFactory.decodeFile(imagePath)

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            val flag = when (screenTarget.uppercase()) {
                                "HOME" -> WallpaperManager.FLAG_SYSTEM
                                "LOCK" -> WallpaperManager.FLAG_LOCK
                                else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                            }
                            wallpaperManager.setBitmap(bitmap, null, true, flag)
                        } else {
                            wallpaperManager.setBitmap(bitmap)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SET_WALLPAPER_FAILED", e.localizedMessage, null)
                    }
                }

                "setVideoWallpaper" -> {
                    // Triggers live wallpaper chooser
                    try {
                        val intent = Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LIVE_CHOOSER_FAILED", e.localizedMessage, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
