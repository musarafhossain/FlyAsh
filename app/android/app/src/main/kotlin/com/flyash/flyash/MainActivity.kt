package com.flyash.flyash

import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Sale receipt → the customer's WhatsApp chat (F17 + 2026-11-16).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flyash/whatsapp")
            .setMethodCallHandler { call, result ->
                if (call.method != "sendFile") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                val phone = call.argument<String>("phone")
                if (path == null || phone == null) {
                    result.error("bad_args", "path and phone are required", null)
                    return@setMethodCallHandler
                }
                result.success(sendFile(File(path), phone, call.argument<String>("text")))
            }
    }

    /**
     * Opens WhatsApp (or WhatsApp Business) on the chat with [phone]
     * (country code + number, digits only) with the PDF attached.
     * Returns "sent" or "not_installed".
     */
    private fun sendFile(file: File, phone: String, text: String?): String {
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        for (app in listOf("com.whatsapp", "com.whatsapp.w4b")) {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                setPackage(app)
                putExtra(Intent.EXTRA_STREAM, uri)
                if (!text.isNullOrEmpty()) putExtra(Intent.EXTRA_TEXT, text)
                // Opens this chat directly instead of the contact picker.
                putExtra("jid", "$phone@s.whatsapp.net")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            try {
                startActivity(intent)
                return "sent"
            } catch (_: ActivityNotFoundException) {
                // Try the next app.
            }
        }
        return "not_installed"
    }
}
