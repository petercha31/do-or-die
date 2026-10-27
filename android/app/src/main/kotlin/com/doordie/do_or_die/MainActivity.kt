package com.doordie.do_or_die

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startYoutubeBlock" -> {
                        ControlPreferences.setYoutubeBlocked(this, true)
                        if (YoutubeBlockService.isEnabled(this)) {
                            sendBroadcast(
                                Intent(YoutubeBlockService.ACTION_APPLY).setPackage(packageName),
                            )
                            result.success("started")
                        } else {
                            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                            result.success("need_accessibility")
                        }
                    }
                    "stopYoutubeBlock" -> {
                        ControlPreferences.setYoutubeBlocked(this, false)
                        result.success("stopped")
                    }
                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        private const val CHANNEL = "do_or_die/app_block"
    }
}
