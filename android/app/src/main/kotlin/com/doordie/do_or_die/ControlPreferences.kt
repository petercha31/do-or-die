package com.doordie.do_or_die

import android.content.Context

object ControlPreferences {
    private const val FILE = "control"
    private const val BLOCK_YOUTUBE = "block_youtube"

    fun setYoutubeBlocked(context: Context, blocked: Boolean) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(BLOCK_YOUTUBE, blocked)
            .apply()
    }

    fun isYoutubeBlocked(context: Context): Boolean {
        return context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            .getBoolean(BLOCK_YOUTUBE, false)
    }
}
