package com.doordie.do_or_die

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast

class YoutubeBlockService : AccessibilityService() {
    private var lastBlockAt = 0L
    private var receiverRegistered = false

    private val applyReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            blockIfYoutubeIsOpen()
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val filter = IntentFilter(ACTION_APPLY)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(applyReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(applyReceiver, filter)
        }
        receiverRegistered = true
        blockIfYoutubeIsOpen()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val windowEvent = event ?: return
        if (windowEvent.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }
        if (windowEvent.packageName?.toString() == YOUTUBE_PACKAGE) {
            goHome()
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        if (receiverRegistered) {
            unregisterReceiver(applyReceiver)
            receiverRegistered = false
        }
        super.onDestroy()
    }

    private fun blockIfYoutubeIsOpen() {
        val activePackage = rootInActiveWindow?.packageName?.toString() ?: return
        if (activePackage == YOUTUBE_PACKAGE) {
            goHome()
        }
    }

    private fun goHome() {
        if (!ControlPreferences.isYoutubeBlocked(this)) {
            return
        }
        val now = SystemClock.elapsedRealtime()
        if (now - lastBlockAt < 800) {
            return
        }
        lastBlockAt = now
        performGlobalAction(GLOBAL_ACTION_HOME)
        Toast.makeText(this, "통제 중에는 유튜브를 열 수 없습니다", Toast.LENGTH_SHORT).show()
    }

    companion object {
        const val ACTION_APPLY = "com.doordie.do_or_die.APPLY_YOUTUBE_BLOCK"
        const val YOUTUBE_PACKAGE = "com.google.android.youtube"

        fun isEnabled(context: Context): Boolean {
            val enabled = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            ) ?: return false
            val expected = ComponentName(context, YoutubeBlockService::class.java)
            return enabled.split(':').any { flattened ->
                ComponentName.unflattenFromString(flattened) == expected
            }
        }
    }
}
