class FarmDevice {
  final String id;
  final String farmId;
  final String deviceUid;
  final String deviceName;
  final String status;
  final DateTime? lastSeen;

  FarmDevice({
    required this.id,
    required this.farmId,
    required this.deviceUid,
    required this.deviceName,
    required this.status,
    this.lastSeen,
  });

  factory FarmDevice.fromMap(Map<String, dynamic> map) {
    return FarmDevice(
      id: map['id'],
      farmId: map['farm_id'],
      deviceUid: map['device_uid'],
      deviceName: map['device_name'],
      status: map['status'] ?? 'Offline',
      lastSeen:
          map['last_seen'] != null ? DateTime.parse(map['last_seen']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farm_id': farmId,
      'device_uid': deviceUid,
      'device_name': deviceName,
      'status': status,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }
}
