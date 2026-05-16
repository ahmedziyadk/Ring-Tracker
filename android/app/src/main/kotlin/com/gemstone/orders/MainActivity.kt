package com.gemstone.orders

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.gemstone.orders/share_caption"
    private var initialSharedText: String? = null
    private var latestSharedText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        captureSharedText(intent, initial = true)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialSharedText" -> result.success(initialSharedText)
                    "getLatestSharedText" -> result.success(latestSharedText)
                    "resetSharedText" -> {
                        initialSharedText = null
                        latestSharedText = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureSharedText(intent, initial = false)
    }

    private fun captureSharedText(intent: Intent?, initial: Boolean) {
        if (intent == null) return

        val action = intent.action
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_SEND_MULTIPLE) return

        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            ?: intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
            ?: return

        if (text.isBlank()) return

        latestSharedText = text
        if (initial) {
            initialSharedText = text
        }
    }
}
