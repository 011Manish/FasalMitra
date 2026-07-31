import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sensor_reading.dart';

class SensorService {
  final _supabase = Supabase.instance.client;

  Future<SensorReading?> getLatestReading(String deviceUid) async {
    try {
      final response = await _supabase
          .from('sensor_readings')
          .select()
          .eq('device_uid', deviceUid)
          .order('timestamp', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      return SensorReading.fromMap(response.first);
    } catch (e) {
      print('Supabase Error: $e');
      return null;
    }
  }
}
