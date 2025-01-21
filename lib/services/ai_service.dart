import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

abstract class AIService {
  Future<String> generateReply({
    required String content,
    required String rolePrompt,
    Map<String, dynamic>? parameters,
  });

  Future<String> analyzeChatImages(
    List<String> base64Images, 
    String? additionalText, {
    String? stylePrompt,
  });
}

class ArkAIService implements AIService {
  static String? _apiKey;
  static String? _chatModelId;
  static String? _visionModelId;
  static String? _baseUrl;
  
  // 初始化配置
  static Future<void> initialize() async {
    try {
      const platform = MethodChannel('com.example.lingxi/config');
      final dynamic rawConfig = await platform.invokeMethod('getConfig');
      
      final Map<String, dynamic> config = Map<String, dynamic>.from(rawConfig as Map);
      
      _apiKey = config['ark.api.key'] as String?;
      _chatModelId = config['ark.chat.model.id'] as String?;
      _visionModelId = config['ark.vision.model.id'] as String?;
      _baseUrl = config['ark.base.url'] as String?;
      
      if (_apiKey == null || _chatModelId == null || 
          _visionModelId == null || _baseUrl == null) {
        throw Exception('配置加载失败: 部分配置项为空');
      }
      
      // 验证配置是否有效
      if (_apiKey!.isEmpty || _chatModelId!.isEmpty || 
          _visionModelId!.isEmpty || _baseUrl!.isEmpty) {
        throw Exception('配置无效: 存在空值');
      }
      
      print('ArkAIService initialized successfully');
      print('Config loaded: $config');
    } catch (e) {
      print('ArkAIService initialization failed: $e');
      rethrow;
    }
  }

  @override
  Future<String> generateReply({
    required String content,
    required String rolePrompt,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey!',
        },
        body: jsonEncode({
          'model': _chatModelId!,  // 使用文本聊天模型
          'messages': [
            {
              'role': 'system',
              'content': rolePrompt
            },
            {
              'role': 'user',
              'content': content
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate reply: $e');
    }
  }

  @override
  Future<String> analyzeChatImages(
    List<String> base64Images, 
    String? additionalText, {
    String? stylePrompt,
  }) async {
    try {
      List<Map<String, dynamic>> content = [];
      
      content.add({
        'type': 'text',
        'text': additionalText?.isNotEmpty == true
            ? '''请分析这些聊天截图，参考我的补充说明：$additionalText
            理解上下文后给出3-5个合适的回复建议。
            要求：
            1. ${stylePrompt ?? '保持自然友好的语气'}
            2. 每个建议要简洁明了，符合正常的聊天语境
            3. 按序号列出，方便选择
            4. 回复要得体，符合对话场景'''
            : '''请分析这些聊天截图，理解上下文后给出3-5个合适的回复建议。
            要求：
            1. ${stylePrompt ?? '保持自然友好的语气'}
            2. 每个建议要简洁明了，符合正常的聊天语境
            3. 按序号列出，方便选择
            4. 回复要得体，符合对话场景''',
      });
      
      // 添加所有图片
      for (String base64Image in base64Images) {
        content.add({
          'type': 'image_url',
          'image_url': {
            'url': base64Image
          },
        });
      }

      final response = await http.post(
        Uri.parse(_baseUrl!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey!',
        },
        body: jsonEncode({
          'model': _visionModelId!,
          'messages': [
            {
              'role': 'system',
              'content': '''你是一个专业的聊天助手，帮助分析聊天记录并给出合适的回复建议。
              你的回复应该：
              1. 保持简洁明了
              2. 符合聊天语境
              3. 按序号列出，方便用户选择
              4. 语气自然友好'''
            },
            {
              'role': 'user',
              'content': content,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['choices'][0]['message']['content'];
        
        // 处理回复格式，确保每个建议都在新行
        List<String> lines = aiResponse.split('\n');
        List<String> formattedLines = [];
        
        for (String line in lines) {
          // 移除行首空白
          line = line.trim();
          // 跳过空行
          if (line.isEmpty) continue;
          // 如果是数字开头的行，添加方括号
          if (RegExp(r'^\d+\.').hasMatch(line)) {
            // 修改这里的实现方式
            String number = RegExp(r'^\d+\.').stringMatch(line) ?? '';
            line = line.replaceFirst(number, '$number [') + ']';
          }
          formattedLines.add(line);
        }
        
        return formattedLines.join('\n');
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to analyze images: $e');
    }
  }
} 