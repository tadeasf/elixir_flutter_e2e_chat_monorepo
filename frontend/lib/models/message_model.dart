class Message {
  final String content;
  final DateTime createdAt;
  final String senderEmail;
  final String? recipientEmail;
  final bool? isSent;

  Message({
    required this.content,
    required this.createdAt,
    required this.senderEmail,
    this.recipientEmail,
    this.isSent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderEmail: json['sender_email'] as String,
      recipientEmail: json['recipient_email'] as String?,
      isSent: json['is_sent'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'sender_email': senderEmail,
      'recipient_email': recipientEmail,
      'is_sent': isSent,
    };
  }

  @override
  String toString() {
    return 'Message{content: $content, createdAt: $createdAt, senderEmail: $senderEmail, recipientEmail: $recipientEmail, isSent: $isSent}';
  }
}
