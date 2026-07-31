import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sensor_reading.dart';
import '../services/sensor_service.dart';

import '../widgets/sensor_card.dart';
import '../widgets/status_banner.dart';
import '../widgets/greenhouse_card.dart';
import '../widgets/irrigation_card.dart';

class FarmDashboard extends StatefulWidget {
  final String farmName;

  const FarmDashboard({
    super.key,
    required this.farmName,
  });

  @override
  State<FarmDashboard> createState() => _FarmDashboardState();
}

class _FarmDashboardState extends State<FarmDashboard> {
  final SensorService _sensorService = SensorService();

  SensorReading? _reading;

  bool _loading = true;
  bool _irrigationOn = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    loadSensor();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => loadSensor(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadSensor() async {
    try {
      final data = await _sensorService.getLatestReading('ESP32_001');

      if (!mounted) return;

      setState(() {
        _reading = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        _reading = null;
        _loading = false;
      });
    }
  }

  bool get isLive => _reading != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          widget.farmName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadSensor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StatusBanner(
              isLive: isLive,
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: .95,
                children: [
                  SensorCard(
                    title: 'Soil Moisture',
                    value: isLive
                        ? '${_reading!.soilMoisture.toStringAsFixed(1)}%'
                        : '--',
                    icon: Icons.water_drop,
                    color: Colors.blue,
                  ),
                  SensorCard(
                    title: 'Temperature',
                    value: isLive
                        ? '${_reading!.temperature.toStringAsFixed(1)}°C'
                        : '--',
                    icon: Icons.thermostat,
                    color: Colors.deepOrange,
                  ),
                  SensorCard(
                    title: 'Humidity',
                    value: isLive
                        ? '${_reading!.humidity.toStringAsFixed(1)}%'
                        : '--',
                    icon: Icons.cloud,
                    color: Colors.teal,
                  ),
                  IrrigationCard(
                    isOn: _irrigationOn,
                    onPressed: () {
                      setState(() {
                        _irrigationOn = !_irrigationOn;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _irrigationOn
                                ? 'Automatic irrigation enabled'
                                : 'Automatic irrigation disabled',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  GreenhouseCard(
                    status: isLive ? 'Healthy' : 'Offline',
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 8),
                        Text(
                          'Sensor Information',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.memory, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Device:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isLive ? _reading!.deviceUid : 'ESP32 not connected',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Last Updated:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isLive
                              ? _reading!.timestamp
                                  .toLocal()
                                  .toString()
                                  .substring(0, 19)
                              : '--',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          isLive ? Icons.check_circle : Icons.sensors_off,
                          color: isLive ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isLive
                              ? 'Receiving live sensor data'
                              : 'Waiting for ESP32 to upload data',
                          style: TextStyle(
                            color: isLive ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
