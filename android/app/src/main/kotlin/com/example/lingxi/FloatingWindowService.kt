package com.example.lingxi

import android.animation.ValueAnimator
import android.app.Service
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.Point
import android.graphics.Rect
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import android.view.*
import android.view.animation.DecelerateInterpolator
import android.widget.Button
import android.widget.EditText
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.flutter.embedding.android.FlutterView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import kotlin.math.abs
import android.widget.PopupMenu
import androidx.core.content.ContextCompat
import android.view.Menu
import android.view.LayoutInflater

class FloatingWindowService : Service() {
    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var flutterView: FlutterView? = null
    private var params: WindowManager.LayoutParams? = null
    private var chatAdapter: ChatAdapter? = null
    private var recyclerView: RecyclerView? = null
    
    private var initialX: Int = 0
    private var initialY: Int = 0
    private var initialTouchX: Float = 0f
    private var initialTouchY: Float = 0f
    private var isMoving = false
    private var lastClickTime: Long = 0
    private var currentMode = "help" // 当前模式
    private var replyOptionsAdapter: ReplyOptionsAdapter? = null
    private var loadingView: View? = null
    private var closeView: View? = null
    private var closeViewParams: WindowManager.LayoutParams? = null
    private var isInCloseArea = false
    private var longPressHandler = Handler(Looper.getMainLooper())
    private var longPressRunnable: Runnable? = null
    private var currentStyle = "自然"  // 默认风格
    private var titleText: TextView? = null  // 添加标题文本视图引用
    private val styles = listOf(
        "自然" to "以自然的方式回复，保持对话流畅",
        "高情商" to "以高情商的方式回复，展现良好的沟通理解能力和共情能力",
        "幽默风趣" to "以幽默风趣的方式回复，适当加入一些俏皮话或有趣的表达",
        "正式礼貌" to "以正式礼貌的方式回复，保持适当的距离感和尊重",
        "温柔体贴" to "以温柔体贴的方式回复，展现关心和善解人意",
        "简洁干练" to "以简洁干练的方式回复，直接表达核心意思"
    )

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (floatingView == null) {
            createFloatingWindow()
        }
        return START_STICKY
    }

    private fun createFloatingWindow() {
        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        
        params?.gravity = Gravity.TOP or Gravity.START
        params?.x = 0
        params?.y = 100

        floatingView = LayoutInflater.from(this).inflate(R.layout.floating_window, null)
        setupChatUI(floatingView!!)
        
        // 获取屏幕尺寸
        val display = windowManager?.defaultDisplay
        val size = Point()
        display?.getSize(size)
        val screenWidth = size.x
        
        // 设置触摸事件
        val floatingBall = floatingView?.findViewById<View>(R.id.floating_ball)
        val expandedView = floatingView?.findViewById<View>(R.id.expanded_view)
        val headerView = floatingView?.findViewById<View>(R.id.header_layout)

        // 小圆球的触摸事件
        floatingBall?.setOnTouchListener(createTouchListener(screenWidth, floatingBall, expandedView))

        // 展开窗口的标题栏触摸事件
        headerView?.setOnTouchListener(createTouchListener(screenWidth, floatingBall, expandedView))

        // 设置最小化按钮
        floatingView?.findViewById<View>(R.id.btn_collapse)?.setOnClickListener {
            floatingBall?.visibility = View.VISIBLE
            expandedView?.visibility = View.GONE
            params?.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
            windowManager?.updateViewLayout(floatingView, params)
        }

        // 创建关闭区域视图
        closeView = LayoutInflater.from(this).inflate(R.layout.close_area, null)
        closeViewParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM
        }

        windowManager?.addView(floatingView, params)
    }

    private fun animateToEdge(targetX: Int) {
        val startX = params?.x ?: 0
        val animator = ValueAnimator.ofInt(startX, targetX)
        animator.interpolator = DecelerateInterpolator()
        animator.duration = 200
        
        animator.addUpdateListener { animation ->
            params?.x = animation.animatedValue as Int
            windowManager?.updateViewLayout(floatingView, params)
        }
        
        animator.start()
    }

    private fun updateTitle() {
        titleText?.text = if (currentStyle == "自然") {
            "灵犀AI助手"
        } else {
            "灵犀AI助手（${currentStyle}）"
        }
    }

    private fun setupChatUI(view: View) {
        val inputMessage = view.findViewById<EditText>(R.id.input_message)
        val btnRegenerate = view.findViewById<Button>(R.id.btn_regenerate)
        val btnPaste = view.findViewById<ImageButton>(R.id.btn_paste)
        val inputHint = view.findViewById<TextView>(R.id.input_hint)
        val modeGroup = view.findViewById<RadioGroup>(R.id.mode_group)
        val replyOptionsList = view.findViewById<RecyclerView>(R.id.reply_options_list)

        // 模式切换监听
        modeGroup.setOnCheckedChangeListener { _, checkedId ->
            currentMode = when (checkedId) {
                R.id.mode_help -> {
                    inputHint.text = "请输入对方的话："
                    inputMessage.hint = "在这里粘贴对方的话..."
                    "help"
                }
                R.id.mode_polish -> {
                    inputHint.text = "请输入需要润色的话："
                    inputMessage.hint = "在这里输入需要润色的内容..."
                    "polish"
                }
                R.id.mode_emotion -> {
                    inputHint.text = "请输入情感问题："
                    inputMessage.hint = "在这里描述你的情感问题..."
                    "emotion"
                }
                else -> "help"
            }
        }

        // 初始化标题文本视图
        titleText = view.findViewById(R.id.title_text)
        titleText?.text = "灵犀AI助手"
        
        // 设置风格选择按钮
        val btnStyle = view.findViewById<ImageButton>(R.id.btn_style)
        btnStyle.background = ContextCompat.getDrawable(this, R.drawable.circle_button_ripple)

        // 更新按钮状态
        updateStyleButton(btnStyle)

        // 创建弹出菜单
        val popupMenu = PopupMenu(this, btnStyle)
        styles.forEachIndexed { index, pair ->
            popupMenu.menu.add(Menu.NONE, index, Menu.NONE, pair.first)
        }

        // 设置菜单项点击监听
        popupMenu.setOnMenuItemClickListener { item ->
            currentStyle = styles[item.itemId].first
            updateStyleButton(btnStyle)
            updateTitle()  // 更新标题
            
            // 显示选中提示
            Toast.makeText(this, "已切换到${currentStyle}风格", Toast.LENGTH_SHORT).show()
            true
        }

        btnStyle.setOnClickListener {
            popupMenu.show()
        }

        // 添加长按提示
        btnStyle.setOnLongClickListener {
            Toast.makeText(this, "当前风格：$currentStyle", Toast.LENGTH_SHORT).show()
            true
        }

        // 在生成回复时使用选中的风格
        view.findViewById<Button>(R.id.btn_generate)?.setOnClickListener {
            val inputMessage = view.findViewById<EditText>(R.id.input_message)?.text?.toString()
            if (!inputMessage.isNullOrBlank()) {
                // 获取当前选中风格的提示词
                val stylePrompt = styles.find { it.first == currentStyle }?.second
                generateReply(inputMessage, stylePrompt)
            }
        }

        // 添加粘贴按钮点击事件
        btnPaste.setOnClickListener {
            val clipboardManager = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
            if (clipboardManager.hasPrimaryClip()) {
                val clipData = clipboardManager.primaryClip
                val text = clipData?.getItemAt(0)?.text?.toString()
                if (text != null) {
                    // 移除中括号
                    val cleanText = text.replace("[", "").replace("]", "")
                    inputMessage.setText(cleanText)
                    Toast.makeText(this, "已粘贴剪切板内容", Toast.LENGTH_SHORT).show()
                }
            }
        }

        // 重新生成按钮点击事件
        btnRegenerate.setOnClickListener {
            // 使用上一次的模式重新生成
            generateReply(inputMessage.toString(), currentMode)
        }

        replyOptionsList.layoutManager = LinearLayoutManager(this)
        replyOptionsAdapter = ReplyOptionsAdapter()
        replyOptionsList.adapter = replyOptionsAdapter

        // 初始化加载视图
        loadingView = view.findViewById(R.id.loading_layout)
        loadingView?.visibility = View.GONE

        // 初始化标题
        updateTitle()
    }

    private fun updateStyleButton(button: ImageButton) {
        // 更新按钮颜色和提示文本
        if (currentStyle != "自然") {
            button.setColorFilter(ContextCompat.getColor(this, R.color.colorPrimary))
            button.contentDescription = "当前风格：$currentStyle（点击切换）"
            
            // 添加选中标记
            button.setImageResource(R.drawable.ic_style_selected)
        } else {
            button.setColorFilter(ContextCompat.getColor(this, R.color.grey_600))
            button.contentDescription = "选择回复风格（当前：自然）"
            
            // 使用默认图标
            button.setImageResource(R.drawable.ic_style)
        }
    }

    private fun generateReply(message: String, stylePrompt: String?) {
        if (message.isBlank()) {
            Toast.makeText(this, "请先输入内容", Toast.LENGTH_SHORT).show()
            return
        }

        // 显示加载提示
        loadingView?.visibility = View.VISIBLE
        replyOptionsAdapter?.setOptions(emptyList(), currentMode)

        // 根据不同模式构建 prompt
        val prompt = when (currentMode) {
            "help" -> """
                你是一个聊天高手，现在对方说：
                "$message"
                请给出3-5种不同风格的回复建议，每个建议要简洁明了，符合正常的聊天语境。
                要求按以下格式输出：
                1. [第一种回复建议]
                2. [第二种回复建议]
                3. [第三种回复建议]
                ...
            """.trimIndent()
            
            "polish" -> """
                你是一位语言大师，现在我输入的话是：
                "$message"
                请帮我对这段话进行润色，使其表达更加流畅、优美，同时不改变原意。
                只需要直接返回润色后的文字，不要包含任何解释或其他内容。
            """.trimIndent()
            
            "emotion" -> """
                你是一位资深情感专家，现在我有一个情感方面的问题：
                "$message"
                请按以下格式提供专业的分析和建议：
                
                【问题分析】
                (简要分析问题的核心和关键点)
                
                【情感解读】
                (从情感角度解读当前状况)
                
                【建议方案】
                1. xxx
                2. xxx
                3. xxx
                
                【温馨提示】
                (一句温暖的话作为结尾)
                
                请确保回答富有同理心和洞察力，语言要温和、专业。
            """.trimIndent()
            
            else -> "请回复以下消息：$message"
        }

        // 在生成回复时使用风格提示词
        val finalPrompt = stylePrompt?.let { "$it\n\n$prompt" } ?: prompt

        // 调用 API 生成回复
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val response = callArkAPI(finalPrompt)
                withContext(Dispatchers.Main) {
                    // 隐藏加载提示
                    loadingView?.visibility = View.GONE
                    
                    when (currentMode) {
                        "help" -> {
                            val options = parseReplyOptions(response)
                            replyOptionsAdapter?.setOptions(options, currentMode)
                        }
                        "polish" -> {
                            replyOptionsAdapter?.setOptions(listOf(response.trim()), currentMode)
                        }
                        "emotion" -> {
                            // 处理情感模式的回复，保持格式
                            val formattedResponse = response
                                .replace("【", "\n【")  // 确保每个段落前有换行
                                .replace("】", "】\n")  // 确保每个标题后有换行
                                .trim()
                            replyOptionsAdapter?.setOptions(listOf(formattedResponse), currentMode)
                        }
                        else -> {
                            replyOptionsAdapter?.setOptions(listOf(response), currentMode)
                        }
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    // 隐藏加载提示
                    loadingView?.visibility = View.GONE
                    replyOptionsAdapter?.setOptions(listOf("生成回复失败：${e.message}"), currentMode)
                }
            }
        }
    }

    private fun parseReplyOptions(response: String): List<String> {
        return response.lines()
            .filter { it.matches(Regex("^\\d+\\..*")) }
            .map { it.replaceFirst(Regex("^\\d+\\.\\s*"), "").trim() }
    }

    private suspend fun callArkAPI(content: String): String {
        val client = OkHttpClient()
        val json = JSONObject().apply {
            put("model", BuildConfig.ARK_MODEL_ID)
            put("messages", JSONArray().apply {
                put(JSONObject().apply {
                    put("role", "system")
                    put("content", "你是一个专业的聊天回复助手，帮助用户生成合适的回复内容。")
                })
                put(JSONObject().apply {
                    put("role", "user")
                    put("content", content)
                })
            })
        }

        val request = Request.Builder()
            .url("https://ark.cn-beijing.volces.com/api/v3/chat/completions")
            .addHeader("Content-Type", "application/json")
            .addHeader("Authorization", "Bearer ${BuildConfig.ARK_API_KEY}")
            .post(json.toString().toRequestBody("application/json".toMediaType()))
            .build()

        return withContext(Dispatchers.IO) {
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) throw IOException("Unexpected code $response")
                
                val responseBody = JSONObject(response.body?.string() ?: "")
                val message = responseBody.getJSONArray("choices")
                    .getJSONObject(0)
                    .getJSONObject("message")
                    .getString("content")

                // 添加使用情况统计
                val usage = responseBody.getJSONObject("usage")
                val promptTokens = usage.getInt("prompt_tokens")
                val completionTokens = usage.getInt("completion_tokens")
                val totalTokens = usage.getInt("total_tokens")

                // 返回格式化的结果
                buildString {
                    append(message)
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        closeView?.let { if (it.parent != null) windowManager?.removeView(it) }
        floatingView?.let { if (it.parent != null) windowManager?.removeView(it) }
    }

    // 抽取触摸事件处理逻辑为单独的方法
    private fun createTouchListener(screenWidth: Int, floatingBall: View?, expandedView: View?): View.OnTouchListener {
        return View.OnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params?.x ?: 0
                    initialY = params?.y ?: 0
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isMoving = false
                    lastClickTime = System.currentTimeMillis()

                    // 设置长按显示关闭区域
                    longPressRunnable = Runnable {
                        if (floatingBall?.visibility == View.VISIBLE) {
                            closeView?.visibility = View.VISIBLE
                            windowManager?.addView(closeView, closeViewParams)
                        }
                    }
                    longPressHandler.postDelayed(longPressRunnable!!, 500)
                    true
                }
                
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = (event.rawX - initialTouchX).toInt()
                    val deltaY = (event.rawY - initialTouchY).toInt()
                    
                    if (abs(deltaX) > 5 || abs(deltaY) > 5) {
                        isMoving = true
                        
                        params?.x = initialX + deltaX
                        params?.y = initialY + deltaY
                        windowManager?.updateViewLayout(floatingView, params)

                        // 检查是否在关闭区域
                        if (closeView?.parent != null) {
                            val location = IntArray(2)
                            closeView?.findViewById<View>(R.id.close_icon)?.getLocationOnScreen(location)
                            val closeIconX = location[0]
                            val closeIconY = location[1]
                            val closeIconWidth = closeView?.findViewById<View>(R.id.close_icon)?.width ?: 0
                            val closeIconHeight = closeView?.findViewById<View>(R.id.close_icon)?.height ?: 0

                            // 创建关闭图标的区域
                            val closeArea = Rect(
                                closeIconX,
                                closeIconY,
                                closeIconX + closeIconWidth,
                                closeIconY + closeIconHeight
                            )

                            // 检查悬浮球是否在关闭区域内
                            val ballCenterX = event.rawX.toInt()
                            val ballCenterY = event.rawY.toInt()
                            isInCloseArea = closeArea.contains(ballCenterX, ballCenterY)

                            // 更新关闭按钮状态
                            closeView?.findViewById<ImageView>(R.id.close_icon)?.setBackgroundResource(
                                if (isInCloseArea) R.drawable.close_button_bg_active 
                                else R.drawable.close_button_bg
                            )
                        }
                    }
                    true
                }
                
                MotionEvent.ACTION_UP -> {
                    longPressHandler.removeCallbacks(longPressRunnable!!)
                    
                    if (closeView?.parent != null) {
                        if (isInCloseArea) {
                            // 关闭悬浮窗
                            closeFloatingWindow()
                        }
                        try {
                            windowManager?.removeView(closeView)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    } else if (!isMoving && System.currentTimeMillis() - lastClickTime < 200) {
                        // 点击事件处理
                        if (floatingBall?.visibility == View.VISIBLE) {
                            floatingBall.visibility = View.GONE
                            expandedView?.visibility = View.VISIBLE
                            params?.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
                            windowManager?.updateViewLayout(floatingView, params)
                        }
                    } else if (floatingBall?.visibility == View.VISIBLE) {
                        // 贴边动画
                        val targetX = if (params?.x ?: 0 > screenWidth / 2) screenWidth - view.width else 0
                        animateToEdge(targetX)
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun closeFloatingWindow() {
        try {
            // 移除所有视图
            if (closeView?.parent != null) {
                windowManager?.removeView(closeView)
            }
            if (floatingView?.parent != null) {
                windowManager?.removeView(floatingView)
            }
            
            // 停止服务
            stopSelf()
            
            // 发送广播
            val intent = Intent("com.example.lingxi.FLOATING_WINDOW_CLOSED")
            intent.addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES)
            // 添加包名以确保广播能被正确接收
            intent.setPackage(packageName)
            sendBroadcast(intent)
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

// 聊天消息数据类
data class ChatMessage(
    val content: String,
    val isUser: Boolean,
    val timestamp: Long = System.currentTimeMillis()
)

// 聊天适配器
class ChatAdapter : RecyclerView.Adapter<ChatAdapter.MessageViewHolder>() {
    private val messages = mutableListOf<ChatMessage>()

    fun addMessage(message: ChatMessage) {
        messages.add(message)
        notifyItemInserted(messages.size - 1)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MessageViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_chat_message, parent, false)
        return MessageViewHolder(view)
    }

    override fun onBindViewHolder(holder: MessageViewHolder, position: Int) {
        holder.bind(messages[position])
    }

    override fun getItemCount() = messages.size

    inner class MessageViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        private val userMessage = view.findViewById<TextView>(R.id.user_message)
        private val aiMessage = view.findViewById<TextView>(R.id.ai_message)

        fun bind(message: ChatMessage) {
            if (message.isUser) {
                userMessage.visibility = View.VISIBLE
                aiMessage.visibility = View.GONE
                userMessage.text = message.content
            } else {
                userMessage.visibility = View.GONE
                aiMessage.visibility = View.VISIBLE
                aiMessage.text = message.content
            }
        }
    }
}

// 添加回复选项适配器
class ReplyOptionsAdapter : RecyclerView.Adapter<ReplyOptionsAdapter.ViewHolder>() {
    private val _options = mutableListOf<String>()
    val options: List<String> get() = _options.toList()
    
    // 添加当前模式属性
    var currentMode: String = "help"
        private set
    
    fun setOptions(newOptions: List<String>, mode: String = "help") {
        _options.clear()
        _options.addAll(newOptions)
        currentMode = mode
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.reply_option_item, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val option = options[position]
        holder.bind(option, position, currentMode)
    }

    override fun getItemCount() = _options.size

    inner class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val numberView: TextView = view.findViewById(R.id.reply_number)
        val optionText: TextView = view.findViewById(R.id.reply_option)

        fun bind(option: String, position: Int, mode: String) {
            itemView.setOnClickListener {
                val clipboardManager = itemView.context
                    .getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                val clip = ClipData.newPlainText("AI回复", option)
                clipboardManager.setPrimaryClip(clip)
                Toast.makeText(itemView.context, "已复制到剪贴板", Toast.LENGTH_SHORT).show()
            }

            when (mode) {
                "polish" -> {
                    numberView.visibility = View.GONE
                    optionText.text = option
                }
                else -> {
                    numberView.visibility = View.VISIBLE
                    numberView.text = "${position + 1}"
                    optionText.text = option.replaceFirst(Regex("^\\d+\\.\\s*"), "")
                }
            }
        }
    }
} 