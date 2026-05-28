package com.example.c001apk.flutter

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Build.VERSION.SDK_INT
import android.os.Environment
import android.webkit.MimeTypeMap;
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "samples.flutter.dev/channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "downloadApk") {
                val url = call.argument<String>("url")
                val name = call.argument<String>("name")
                if (url != null && name != null) {
                    val response = downloadApk(url, name)
                    result.success(response)
                } else {
                    result.success(false)
                }
            } else if (call.method == "exportData") {
                val data = call.argument<String>("data")
                val fileName = call.argument<String>("fileName")
                if (data != null && fileName != null) {
                    exportData = data
                    exportData(fileName)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private var exportData: String? = null

    private val backupSAFLauncher =
        registerForActivityResult(ActivityResultContracts.CreateDocument("application/json")) backup@{ uri ->
            if (uri == null) return@backup
            try{
                contentResolver.openOutputStream(uri).use { output ->
                    if (output == null)
                        return@backup
                    else if (exportData != null) {
                            output.write(exportData!!.toByteArray())
                            exportData = null
                            Toast.makeText(this, "导出成功", Toast.LENGTH_SHORT).show()
                        }
                    else
                        Toast.makeText(this, "null", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this, e.toString(), Toast.LENGTH_SHORT).show()
            }
    }

    private fun exportData(fileName: String) {
        try {
            backupSAFLauncher.launch(fileName)
        } catch (e: Exception) {
            Toast.makeText(this, e.toString(), Toast.LENGTH_SHORT).show()
        }
    }

    private fun downloadApk(url: String, name: String): Boolean {
        try {
            val mimeType = MimeTypeMap.getSingleton()
                .getMimeTypeFromExtension(MimeTypeMap.getFileExtensionFromUrl(url))
            val downloadManager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            val request = DownloadManager
                .Request(Uri.parse(url))
                .setMimeType(mimeType)
                .setTitle(name)
                .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, name)
            if (SDK_INT < 29) {
                request.allowScanningByMediaScanner()
                request.setVisibleInDownloadsUi(true)
            }
            downloadManager.enqueue(request)
            return true
        } catch (e: Exception) {
            return false
        }
    }

}
