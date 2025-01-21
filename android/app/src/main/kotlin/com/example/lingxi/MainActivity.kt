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
import android.app.Dialog
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.view.Window
import android.view.WindowManager
import android.widget.TextView
import android.widget.CheckBox
import android.widget.Button
import java.io.FileInputStream
import java.util.Properties
import java.io.File

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
        
        // 显示开屏通知
        showStartupNotice()
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

        // 添加配置通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.lingxi/config")
            .setMethodCallHandler { call, result ->
                if (call.method == "getConfig") {
                    try {
                        // 显式指定 Map 类型为 Map<String, String>
                        val config: Map<String, String> = mapOf(
                            "ark.api.key" to (BuildConfig.ARK_API_KEY ?: ""),
                            "ark.chat.model.id" to (BuildConfig.ARK_CHAT_MODEL_ID ?: ""),
                            "ark.vision.model.id" to (BuildConfig.ARK_VISION_MODEL_ID ?: ""),
                            "ark.base.url" to (BuildConfig.ARK_BASE_URL ?: "")
                        )
                        
                        // 验证配置
                        config.forEach { (key, value) ->
                            if (value.isEmpty()) {
                                throw Exception("Configuration error: $key is empty")
                            }
                        }
                        
                        // 使用 HashMap 来确保类型兼容性
                        val resultMap = HashMap<String, String>(config)
                        result.success(resultMap)
                    } catch (e: Exception) {
                        result.error(
                            "CONFIG_ERROR",
                            "Failed to load configuration: ${e.message}",
                            e.stackTraceToString()
                        )
                    }
                } else {
                    result.notImplemented()
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

    private fun showStartupNotice() {
        // 检查是否需要显示
        val prefs = getSharedPreferences("app_settings", Context.MODE_PRIVATE)
        val shouldShow = !prefs.getBoolean("dont_show_startup_notice", false)
        
        if (shouldShow) {
            val dialog = Dialog(this)
            dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)
            dialog.setContentView(R.layout.startup_notice_dialog)
            
            // 设置对话框宽度为屏幕宽度的 85%
            val window = dialog.window
            window?.setLayout(
                (resources.displayMetrics.widthPixels * 0.85).toInt(),
                WindowManager.LayoutParams.WRAP_CONTENT
            )
            window?.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            
            // 设置通知内容
            val contentView = dialog.findViewById<TextView>(R.id.notice_content)
            contentView.text = """
            应用仍处于开发阶段，
            功能未完善，
            目前只有悬浮窗功能和AI聊天功能，
            后续会添加更多功能。
            """.trimIndent()
            
            // 不再提示复选框
            val dontShowAgain = dialog.findViewById<CheckBox>(R.id.dont_show_again)
            
            // 确认按钮
            dialog.findViewById<Button>(R.id.btn_confirm).setOnClickListener {
                if (dontShowAgain.isChecked) {
                    // 保存不再显示的设置
                    prefs.edit().putBoolean("dont_show_startup_notice", true).apply()
                }
                dialog.dismiss()
            }
            
            // 显示对话框
            dialog.show()
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
