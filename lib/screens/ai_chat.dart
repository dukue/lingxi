import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/floating_window_service.dart';
import '../services/ai_service.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class AIChat extends StatefulWidget {
  @override
  _AIChatState createState() => _AIChatState();
}

class _AIChatState extends State<AIChat> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<File> _selectedImages = [];
  String? _aiResponse;
  List<String> _aiResponseList = [];
  String _selectedStyle = '自然'; // 默认风格
  
  final List<String> _replyStyles = [
    '自然',
    '高情商',
    '幽默风趣',
    '正式礼貌',
    '温柔体贴',
    '简洁干练',
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<List<String>> _imagesToBase64(List<File> imageFiles) async {
    List<String> base64Images = [];
    for (var file in imageFiles) {
      List<int> imageBytes = await file.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      String extension = file.path.split('.').last.toLowerCase();
      base64Images.add('data:image/$extension;base64,$base64Image');
    }
    return base64Images;
  }

  Future<void> _analyzeImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 保存当前输入内容
      final additionalText = _messageController.text;

      // 清空输入框
      _messageController.clear();

      // 转换图片为 base64
      List<String> base64Images = [];
      for (File image in _selectedImages) {
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64.encode(bytes)}';
        base64Images.add(base64Image);
      }

      // 调用 AI 服务
      final aiService = ArkAIService();
      final response = await aiService.analyzeChatImages(
        base64Images,
        additionalText,
        stylePrompt: _selectedStyle == '自然' ? null : _selectedStyle,
      );

      setState(() {
        _aiResponse = response;
        _aiResponseList = response.split('\n');
        _isLoading = false;
        _selectedImages.clear(); // 清空已选图片
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _aiResponse = '分析失败：$e';
      });
    }
  }

  // 添加文本发送方法
  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 保存当前输入内容
      final message = _messageController.text;

      // 清空输入框
      _messageController.clear();

      // 调用 AI 服务
      final aiService = ArkAIService();
      final response = await aiService.generateReply(
        content: message,
        rolePrompt: _selectedStyle == '自然' ? 
            '以自然的方式回复' : 
            '以${_selectedStyle}的方式回复',
      );

      setState(() {
        _aiResponse = response;
        _aiResponseList = response.split('\n');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _aiResponse = '发送失败：$e';
      });
    }
  }

  void _clearImages() {
    setState(() {
      _selectedImages.clear();
      _aiResponse = null;
    });
  }

  void _copyToClipboard(String text) {
    final cleanText = text.replaceFirst(RegExp(r'^\d+\.\s*'), '').replaceAll(RegExp(r'[\[\]]'), '');
    Clipboard.setData(ClipboardData(text: cleanText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI聊天助手'),
        actions: [
          if (_selectedImages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearImages,
            ),
          IconButton(
            icon: Icon(Icons.launch),
            onPressed: () async {
              await FloatingWindowService.requestPermission();
              await FloatingWindowService.show();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 风格选择区域
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择回复风格：',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _replyStyles.map((style) {
                      final isSelected = style == _selectedStyle;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(style),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedStyle = style;
                              });
                            }
                          },
                          selectedColor: Theme.of(context).primaryColor,
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 13,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 图片预览区域
          if (_selectedImages.isNotEmpty)
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return Padding(
                      padding: EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: Icon(Icons.add_photo_alternate),
                        onPressed: _pickImage,
                      ),
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        Image.file(
                          _selectedImages[index],
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                                if (_selectedImages.isEmpty) {
                                  _aiResponse = null;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // 消息列表区域
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                if (_isLoading)
                  Center(child: CircularProgressIndicator())
                else if (_aiResponseList.isNotEmpty)
                  ...List.generate(_aiResponseList.length, (index) {
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _copyToClipboard(_aiResponseList[index]),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _aiResponseList[index].replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              Icon(Icons.copy, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                else if (_aiResponse != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(_aiResponse!),
                  ),
              ],
            ),
          ),

          // 底部输入区域
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _selectedImages.isEmpty ? _pickImage : null,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _selectedImages.isEmpty 
                          ? '输入消息或上传聊天截图...'
                          : '添加补充说明（可选）...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _selectedImages.isEmpty ? null : _analyzeImages,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
} 