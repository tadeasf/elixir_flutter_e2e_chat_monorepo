class Message {
  final String content;
  final DateTime createdAt;
  final String senderEmail;

  Message({
    required this.content,
    required this.createdAt,
    required this.senderEmail,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      senderEmail: json['sender_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'sender_email': senderEmail,
    };
  }
}
