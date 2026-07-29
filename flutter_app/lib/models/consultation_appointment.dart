class ConsultationAppointment {
  final String id;
  final String userId;
  final String expertId;
  final String? farmId;
  final DateTime requestedAt;
  final DateTime? scheduledFor;
  final String status;

  ConsultationAppointment({
    required this.id,
    required this.userId,
    required this.expertId,
    this.farmId,
    required this.requestedAt,
    this.scheduledFor,
    required this.status,
  });

  factory ConsultationAppointment.fromMap(Map<String, dynamic> row) => ConsultationAppointment(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        expertId: row['expert_id'] as String,
        farmId: row['farm_id'] as String?,
        requestedAt: DateTime.parse(row['requested_at'] as String),
        scheduledFor: row['scheduled_for'] == null
            ? null
            : DateTime.parse(row['scheduled_for'] as String),
        status: row['status'] as String,
      );
}

const appointmentStatuses = ['pending', 'confirmed', 'completed', 'cancelled'];
