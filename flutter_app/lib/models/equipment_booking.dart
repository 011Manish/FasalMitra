class EquipmentBooking {
  EquipmentBooking({
    required this.id,
    required this.equipmentId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalAmount,
    required this.requestedAt,
    this.placeId,
    this.placeName,
    this.placeAddress,
  });

  final String id;
  final String equipmentId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double totalAmount;
  final DateTime requestedAt;
  final String? placeId;
  final String? placeName;
  final String? placeAddress;

  int get days => endDate.difference(startDate).inDays + 1;

  factory EquipmentBooking.fromMap(Map<String, dynamic> m) => EquipmentBooking(
        id: m['id'] as String,
        equipmentId: m['equipment_id'] as String,
        startDate: DateTime.parse(m['start_date'] as String),
        endDate: DateTime.parse(m['end_date'] as String),
        status: m['status'] as String,
        totalAmount: (m['total_amount'] as num).toDouble(),
        requestedAt: DateTime.parse(m['requested_at'] as String),
        placeId: m['place_id'] as String?,
        placeName: m['place_name'] as String?,
        placeAddress: m['place_address'] as String?,
      );
}
