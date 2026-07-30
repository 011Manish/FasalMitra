class SensorData {
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final bool irrigation;
  final bool greenhouse;

  SensorData({
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.irrigation,
    required this.greenhouse,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      soilMoisture: json['soil_moisture'].toDouble(),
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
      irrigation: json['irrigation'],
      greenhouse: json['greenhouse'],
    );
  }
}
