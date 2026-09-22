package com.azharna.azharna_pro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.MediaMetadataRetriever
import android.graphics.Bitmap
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "azharna/store_video")
            .setMethodCallHandler { call, result ->
                if (call.method != "thumbnail") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path.isNullOrEmpty()) {
                    result.error("invalid_path", "Missing video path", null)
                    return@setMethodCallHandler
                }
                Thread {
                    val retriever = MediaMetadataRetriever()
                    try {
                        retriever.setDataSource(path)
                        val frame = retriever.getFrameAtTime(0)
                        val bytes = frame?.let {
                            val height = (it.height * 240.0 / it.width).toInt().coerceAtLeast(1)
                            val scaled = Bitmap.createScaledBitmap(it, 240, height, true)
                            val output = ByteArrayOutputStream()
                            scaled.compress(Bitmap.CompressFormat.JPEG, 65, output)
                            if (scaled !== it) scaled.recycle()
                            it.recycle()
                            output.toByteArray()
                        }
                        runOnUiThread { result.success(bytes) }
                    } catch (error: Exception) {
                        runOnUiThread { result.error("thumbnail_failed", error.message, null) }
                    } finally {
                        retriever.release()
                    }
                }.start()
            }
    }
}
