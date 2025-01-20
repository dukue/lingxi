import 'package:uuid/uuid.dart';
import 'chat_role.dart';

class ChatHistory {
  final String id;
  final DateTime timestamp;
  final String originalContent;
  final String generatedReply;
  final ChatRole role;

  ChatHistory({
    String? id,
    DateTime? timestamp,
    required this.originalContent,
    required this.generatedReply,
    required this.role,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.timestamp = timestamp ?? DateTime.now();

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      originalContent: json['originalContent'],
      generatedReply: json['generatedReply'],
      role: ChatRole.fromJson(json['role']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'originalContent': originalContent,
      'generatedReply': generatedReply,
      'role': role.toJson(),
    };
  }
} 