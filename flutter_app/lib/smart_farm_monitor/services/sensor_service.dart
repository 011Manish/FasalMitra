import '../models/sensor_data.dart';

class SensorService {
  Future<SensorData> getSensorData(int farmId) async {
    return SensorData(
      soilMoisture: 45,
      temperature: 28,
      humidity: 70,
      irrigation: true,
      greenhouse: true,
    );
  }
}
