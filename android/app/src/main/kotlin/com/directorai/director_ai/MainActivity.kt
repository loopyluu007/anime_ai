package com.directorai.director_ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import android.util.Log
import android.content.ContentValues
import android.provider.MediaStore
import android.os.Build
import android.content.Context
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.directorai.director_ai/gallery"
    private val TAG = "Gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveVideoToGallery" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("INVALID_ARGUMENTS", "Missing filePath", null)
                        return@setMethodCallHandler
                    }

                    GlobalScope.launch(Dispatchers.IO) {
                        try {
                            val savedPath = saveVideoToGallery(filePath)
                            withContext(Dispatchers.Main) {
                                result.success(savedPath)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to save video to gallery", e)
                            withContext(Dispatchers.Main) {
                                result.error("SAVE_FAILED", e.message, null)
                            }
                        }
                    }
                }
                "saveImageToGallery" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("INVALID_ARGUMENTS", "Missing filePath", null)
                        return@setMethodCallHandler
                    }

                    GlobalScope.launch(Dispatchers.IO) {
                        try {
                            val savedPath = saveImageToGallery(filePath)
                            withContext(Dispatchers.Main) {
                                result.success(savedPath)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to save image to gallery", e)
                            withContext(Dispatchers.Main) {
                                result.error("SAVE_FAILED", e.message, null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * 保存视频到相册
     */
    private fun saveVideoToGallery(filePath: String): String {
        val sourceFile = File(filePath)
        if (!sourceFile.exists()) {
            throw IllegalArgumentException("Source file does not exist: $filePath")
        }

        val contentResolver = applicationContext.contentResolver
        val contentValues = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, "Video_${System.currentTimeMillis()}.mp4")
            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/Movies")
            put(MediaStore.Video.Media.IS_PENDING, 1)
        }

        val uri = contentResolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, contentValues)

        uri?.let {
            contentResolver.openOutputStream(it)?.use { output ->
                sourceFile.inputStream().use { input ->
                    input.copyTo(output)
                }
            }

            contentValues.clear()
            contentValues.put(MediaStore.Video.Media.IS_PENDING, 0)
            contentResolver.update(it, contentValues, null, null)

            Log.d(TAG, "Video saved to gallery: $it")
            return it.toString()
        } ?: throw IllegalStateException("Failed to create MediaStore entry")

    }

    /**
     * 保存图片到相册
     */
    private fun saveImageToGallery(filePath: String): String {
        val sourceFile = File(filePath)
        if (!sourceFile.exists()) {
            throw IllegalArgumentException("Source file does not exist: $filePath")
        }

        val contentResolver = applicationContext.contentResolver
        val contentValues = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "Image_${System.currentTimeMillis()}.jpg")
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Movies")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }

        val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)

        uri?.let {
            contentResolver.openOutputStream(it)?.use { output ->
                sourceFile.inputStream().use { input ->
                    input.copyTo(output)
                }
            }

            contentValues.clear()
            contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
            contentResolver.update(it, contentValues, null, null)

            Log.d(TAG, "Image saved to gallery: $it")
            return it.toString()
        } ?: throw IllegalStateException("Failed to create MediaStore entry")

    }
}

