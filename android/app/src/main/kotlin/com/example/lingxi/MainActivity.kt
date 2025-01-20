package com.example.lingxi

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.annotation.NonNull
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.lingxi/floating_window"
    private var methodChannel: MethodChannel? = null
    private var receiver: FloatingWindowReceiver? = null

    companion object {
        private const val OVERLAY_PERMISSION_REQUEST_CODE = 1
        private var instance: MainActivity? = null
        
        fun updateFloatingWindowStatus() {
            instance?.methodChannel?.invokeMethod("onFloatingWindowClosed", null)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // 注册广播接收器
        receiver = FloatingWindowReceiver()
        registerReceiver(
            receiver,
            IntentFilter("com.example.lingxi.FLOATING_WINDOW_CLOSED"),
            Context.RECEIVER_NOT_EXPORTED
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestFloatingWindowPermission" -> {
                    requestFloatingWindowPermission()
                    result.success(null)
                }
                "showFloatingWindow" -> {
                    showFloatingWindow()
                    result.success(null)
                }
                "hideFloatingWindow" -> {
                    hideFloatingWindow()
                    result.success(null)
                }
                "checkFloatingWindowStatus" -> {
                    result.success(checkFloatingWindowStatus())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestFloatingWindowPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${packageName}")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
        }
    }

    private fun showFloatingWindow() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.canDrawOverlays(this)) {
            startService(Intent(this, FloatingWindowService::class.java))
        }
    }

    private fun hideFloatingWindow() {
        stopService(Intent(this, FloatingWindowService::class.java))
    }

    private fun checkFloatingWindowStatus(): Boolean {
        return try {
            val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            manager.getRunningServices(Integer.MAX_VALUE).any { 
                it.service.className == FloatingWindowService::class.java.name 
            }
        } catch (e: Exception) {
            false
        }
    }

    override fun onDestroy() {
        try {
            receiver?.let { unregisterReceiver(it) }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        if (instance == this) {
            instance = null
        }
        super.onDestroy()
    }
}
