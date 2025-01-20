package com.example.lingxi

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class FloatingWindowReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == "com.example.lingxi.FLOATING_WINDOW_CLOSED") {
            MainActivity.updateFloatingWindowStatus()
        }
    }
} 