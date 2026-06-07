package com.catetin

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "catetin/downloads"
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveFile") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val fileName = call.argument<String>("fileName")
            val mimeType = call.argument<String>("mimeType")
            val bytes = call.argument<ByteArray>("bytes")

            if (fileName.isNullOrBlank() || mimeType.isNullOrBlank() || bytes == null) {
                result.error("INVALID_ARGS", "fileName, mimeType, and bytes are required", null)
                return@setMethodCallHandler
            }

            try {
                result.success(saveFileToDownloads(fileName, mimeType, bytes))
            } catch (error: Exception) {
                result.error("SAVE_FAILED", error.message, null)
            }
        }
    }

    private fun saveFileToDownloads(
        fileName: String,
        mimeType: String,
        bytes: ByteArray
    ): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            try {
                saveUsingMediaStore(resolver, fileName, mimeType, bytes)
            } catch (firstError: Exception) {
                val fallbackMime = if (mimeType.contains("csv")) "text/plain" else "application/octet-stream"
                try {
                    saveUsingMediaStore(resolver, fileName, fallbackMime, bytes)
                } catch (secondError: Exception) {
                    throw IllegalStateException("Failed to save even with fallback: ${secondError.message}")
                }
            }
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            )
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }

            val file = File(downloadsDir, fileName)
            FileOutputStream(file).use { output ->
                output.write(bytes)
            }
            file.absolutePath
        }
    }

    private fun saveUsingMediaStore(
        resolver: android.content.ContentResolver,
        fileName: String,
        mimeType: String,
        bytes: ByteArray
    ): String {
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Cannot create MediaStore entry")

        try {
            resolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
            } ?: throw IllegalStateException("Cannot open output stream")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        } catch (e: Exception) {
            try {
                resolver.delete(uri, null, null)
            } catch (cleanupEx: Exception) {}
            throw e
        }
    }
}
