package com.ketik.ketik_prompt

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ketik/inbox")
            .setMethodCallHandler { call, result ->
                if (call.method == "drain") {
                    val p = getSharedPreferences("ketik_inbox", MODE_PRIVATE)
                    val raw = p.getString("inbox", "") ?: ""
                    p.edit().remove("inbox").apply()
                    result.success(if (raw.isEmpty()) emptyList<String>() else raw.split("\u0001"))
                } else result.notImplemented()
            }
    }
}
