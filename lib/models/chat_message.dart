class ChatMessage {
  final String id;
  final String salonId;
  final String userId;
  final String content;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;
  final String? replyToId;
  final Map<String, dynamic> reactions; // {userId: emoji}

  ChatMessage({
    required this.id,
    required this.salonId,
    required this.userId,
    required this.content,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
    this.replyToId,
    this.reactions = const {},
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      salonId: json['salon_id'].toString(),
      userId: json['user_id'].toString(),
      content: json['content'].toString(),
      userName: json['user_name']?.toString() ?? 'Utilisateur',
      userAvatar: json['user_avatar']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      replyToId: json['reply_to_id']?.toString(),
      reactions: json['reactions'] != null
          ? Map<String, dynamic>.from(json['reactions'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salon_id': salonId,
      'user_id': userId,
      'content': content,
      'user_name': userName,
      'user_avatar': userAvatar,
      'created_at': createdAt.toIso8601String(),
      'reply_to_id': replyToId,
      'reactions': reactions,
    };
  }
}
