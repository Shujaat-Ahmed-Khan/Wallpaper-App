package com.bitrops.wallpaper_app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import java.io.File
import kotlin.math.sin

class GyroWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine {
        return GyroEngine()
    }

    inner class GyroEngine : Engine(), SensorEventListener {

        private val handler = Handler(Looper.getMainLooper())
        private var sensorManager: SensorManager? = null
        private var rotationSensor: Sensor? = null

        private var bgBitmap: Bitmap? = null
        private var fgBitmap: Bitmap? = null

        private var isVisible = false
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)

        // Gyroscopic tilt angles and smoothed filters
        private var targetPitch = 0f
        private var targetRoll = 0f
        private var smoothPitch = 0f
        private var smoothRoll = 0f

        // Maximum parallax pixel shifts
        private val maxBgShift = 45f
        private val maxFgShift = 75f
        private val alpha = 0.12f // Low-pass filter smoothing coefficient

        // 60 FPS loop
        private val frameRunnable = object : Runnable {
            override fun run() {
                if (isVisible) {
                    drawFrame()
                    handler.postDelayed(this, 16) // ~60fps
                }
            }
        }

        override fun onCreate(surfaceHolder: SurfaceHolder?) {
            super.onCreate(surfaceHolder)
            sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
            rotationSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
            loadBitmapsFromPreferences()
        }

        private fun loadBitmapsFromPreferences() {
            try {
                val prefs = getSharedPreferences("neon_wallpaper_prefs", Context.MODE_PRIVATE)
                val bgPath = prefs.getString("background_path", null)
                val fgPath = prefs.getString("foreground_path", null)

                if (!bgPath.isNullOrEmpty() && File(bgPath).exists()) {
                    bgBitmap?.recycle()
                    bgBitmap = BitmapFactory.decodeFile(bgPath)
                }
                if (!fgPath.isNullOrEmpty() && File(fgPath).exists()) {
                    fgBitmap?.recycle()
                    fgBitmap = BitmapFactory.decodeFile(fgPath)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        override fun onVisibilityChanged(visible: Boolean) {
            super.onVisibilityChanged(visible)
            isVisible = visible
            if (visible) {
                loadBitmapsFromPreferences()
                rotationSensor?.let {
                    sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
                }
                handler.post(frameRunnable)
            } else {
                sensorManager?.unregisterListener(this)
                handler.removeCallbacks(frameRunnable)
            }
        }

        override fun onSensorChanged(event: SensorEvent?) {
            if (event?.sensor?.type == Sensor.TYPE_ROTATION_VECTOR) {
                val rotationMatrix = FloatArray(9)
                SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)

                val orientationValues = FloatArray(3)
                SensorManager.getOrientation(rotationMatrix, orientationValues)

                // pitch: orientationValues[1], roll: orientationValues[2]
                val pitch = orientationValues[1]
                val roll = orientationValues[2]

                // Clamp angles to reasonable tilt range (-0.5 to 0.5 rad)
                targetPitch = (pitch / 0.5f).coerceIn(-1.0f, 1.0f)
                targetRoll = (roll / 0.5f).coerceIn(-1.0f, 1.0f)
            }
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

        private fun drawFrame() {
            val holder = surfaceHolder ?: return
            var canvas: Canvas? = null

            try {
                canvas = holder.lockCanvas()
                if (canvas != null) {
                    // Apply low-pass filter
                    smoothPitch += alpha * (targetPitch - smoothPitch)
                    smoothRoll += alpha * (targetRoll - smoothRoll)

                    val width = canvas.width.toFloat()
                    val height = canvas.height.toFloat()

                    // Deep Carbon Black background base
                    canvas.drawColor(Color.parseColor("#0A0A10"))

                    // 1. Draw Background Layer (Shifted negatively for deep parallax)
                    bgBitmap?.let { bmp ->
                        val shiftX = -smoothRoll * maxBgShift
                        val shiftY = -smoothPitch * maxBgShift
                        drawLayer(canvas, bmp, width, height, shiftX, shiftY, scaleOverscan = 1.15f)
                    }

                    // 2. Draw Foreground Layer (Shifted positively for pop-out parallax)
                    fgBitmap?.let { bmp ->
                        val shiftX = smoothRoll * maxFgShift
                        val shiftY = smoothPitch * maxFgShift
                        drawLayer(canvas, bmp, width, height, shiftX, shiftY, scaleOverscan = 1.0f)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                if (canvas != null) {
                    try {
                        holder.unlockCanvasAndPost(canvas)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        }

        private fun drawLayer(
            canvas: Canvas,
            bitmap: Bitmap,
            canvasWidth: Float,
            canvasHeight: Float,
            shiftX: Float,
            shiftY: Float,
            scaleOverscan: Float
        ) {
            val bmpWidth = bitmap.width.toFloat()
            val bmpHeight = bitmap.height.toFloat()

            // Calculate center-crop fit with overscan for parallax margin
            val scale = maxOf(canvasWidth / bmpWidth, canvasHeight / bmpHeight) * scaleOverscan
            val scaledW = bmpWidth * scale
            val scaledH = bmpHeight * scale

            val left = (canvasWidth - scaledW) / 2f + shiftX
            val top = (canvasHeight - scaledH) / 2f + shiftY

            val destRect = RectF(left, top, left + scaledW, top + scaledH)
            val srcRect = Rect(0, 0, bitmap.width, bitmap.height)

            canvas.drawBitmap(bitmap, srcRect, destRect, paint)
        }

        override fun onDestroy() {
            super.onDestroy()
            sensorManager?.unregisterListener(this)
            handler.removeCallbacks(frameRunnable)
            bgBitmap?.recycle()
            fgBitmap?.recycle()
            bgBitmap = null
            fgBitmap = null
        }
    }
}
