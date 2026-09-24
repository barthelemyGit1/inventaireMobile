package com.example.inventaire

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
    private val CHANNEL = "inventaire_mtdpce/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveToDownloads") {
                try {
                    val fileName = call.argument<String>("fileName")!!
                    val bytes = call.argument<ByteArray>("bytes")!!
                    val mimeType = call.argument<String>("mimeType")!!
                    result.success(saveToDownloads(fileName, bytes, mimeType))
                } catch (e: Exception) {
                    result.error("SAVE_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    /// Écrit directement dans la collection publique MediaStore.Downloads
    /// (Android 10+, API 29+) — pas de dialogue, pas de permission requise.
    /// Pour Android 9 et moins, écriture directe dans le dossier public
    /// Téléchargements (nécessite WRITE_EXTERNAL_STORAGE dans le manifeste).
    private fun saveToDownloads(fileName: String, bytes: ByteArray, mimeType: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw Exception("Impossible de créer le fichier dans MediaStore")
            contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
            return uri.toString()
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) downloadsDir.mkdirs()
            val file = File(downloadsDir, fileName)
            FileOutputStream(file).use { it.write(bytes) }
            return file.absolutePath
        }
    }
}