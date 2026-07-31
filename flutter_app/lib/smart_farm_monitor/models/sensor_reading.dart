class SensorReading {
  final String id;
  final String deviceUid;

  final double temperature;
  final double humidity;
  final double soilMoisture;

  final bool irrigationOn;
  final String greenhouseStatus;

  final DateTime timestamp;

  SensorReading({
    required this.id,
    required this.deviceUid,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.irrigationOn,
    required this.greenhouseStatus,
    required this.timestamp,
  });

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'].toString(),
      deviceUid: map['device_uid'].toString(),
      temperature: (map['temperature'] ?? 0).toDouble(),
      humidity: (map['humidity'] ?? 0).toDouble(),
      soilMoisture: (map['soil_moisture'] ?? 0).toDouble(),
      irrigationOn: map['irrigation_on'] ?? false,
      greenhouseStatus: map['greenhouse_status'] ?? 'Unknown',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'device_uid': deviceUid,
      'temperature': temperature,
      'humidity': humidity,
      'soil_moisture': soilMoisture,
      'irrigation_on': irrigationOn,
      'greenhouse_status': greenhouseStatus,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
