class ConsultationMessage {
  final String id;
  final String appointmentId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  ConsultationMessage({
    required this.id,
    required this.appointmentId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory ConsultationMessage.fromMap(Map<String, dynamic> row) =>
      ConsultationMessage(
        id: row['id'] as String,
        appointmentId: row['appointment_id'] as String,
        senderId: row['sender_id'] as String,
        body: row['body'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
