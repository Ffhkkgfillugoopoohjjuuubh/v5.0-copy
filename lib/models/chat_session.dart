import 'chat_message.dart';

class ChatSession {
  const ChatSession({
    required this.id,
    required this.name,
    required this.messages,
    required this.isStarred,
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<ChatMessage> messages;
  final bool isStarred;
  final String? projectId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession copyWith({
    String? id,
    String? name,
    List<ChatMessage>? messages,
    bool? isStarred,
    String? projectId,
    bool clearProjectId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      name: name ?? this.name,
      messages: messages ?? this.messages,
      isStarred: isStarred ?? this.isStarred,
      projectId: clearProjectId ? null : projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'messages': messages.map((message) => message.toJson()).toList(),
      'isStarred': isStarred,
      'projectId': projectId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      name: json['name'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map(
            (message) =>
                ChatMessage.fromJson(message as Map<String, dynamic>),
          )
          .toList(),
      isStarred: json['isStarred'] as bool? ?? false,
      projectId: json['projectId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
