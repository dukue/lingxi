import 'package:flutter/material.dart';
import '../services/clipboard_service.dart';
import '../services/ai_service.dart';
import '../services/floating_window_service.dart';

class FloatingChatWindow extends StatefulWidget {
  @override
  _FloatingChatWindowState createState() => _FloatingChatWindowState();
}

class _FloatingChatWindowState extends State<FloatingChatWindow> {
  String? clipboardContent;
  String? generatedReply;
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) {
      return FloatingActionButton(
        mini: true,
        child: Icon(Icons.chat),
        onPressed: () => setState(() => isExpanded = true),
      );
    }

    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.minimize),
            onPressed: () => setState(() => isExpanded = false),
          ),
          Expanded(child: Text('AI聊天助手')),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              // 关闭悬浮窗
              FloatingWindowService.hide();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('原始内容：'),
          Text(clipboardContent ?? '暂无内容'),
          SizedBox(height: 16),
          Text('生成的回复：'),
          Text(generatedReply ?? '等待生成'),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: _getClipboardContent,
            child: Text('获取剪贴板'),
          ),
          ElevatedButton(
            onPressed: _generateReply,
            child: Text('生成回复'),
          ),
        ],
      ),
    );
  }

  Future<void> _getClipboardContent() async {
    final content = await ClipboardService.getClipboardText();
    setState(() {
      clipboardContent = content;
    });
  }

  Future<void> _generateReply() async {
    // TODO: 实现AI回复生成
  }
} 