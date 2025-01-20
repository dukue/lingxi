import 'package:uuid/uuid.dart';

class ChatRole {
  final String id;
  final String name;
  final String description;
  final String prompt;
  final Map<String, dynamic> parameters;

  ChatRole({
    String? id,
    required this.name,
    required this.description,
    required this.prompt,
    Map<String, dynamic>? parameters,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.parameters = parameters ?? {};

  factory ChatRole.fromJson(Map<String, dynamic> json) {
    return ChatRole(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      prompt: json['prompt'],
      parameters: json['parameters'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'prompt': prompt,
      'parameters': parameters,
    };
  }
} 