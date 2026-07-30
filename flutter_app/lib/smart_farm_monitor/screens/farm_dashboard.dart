import 'package:flutter/material.dart';

import '../widgets/greenhouse_card.dart';
import '../widgets/irrigation_card.dart';
import '../widgets/sensor_card.dart';

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
  bool irrigationOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farmName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            const SensorCard(
              title: "Soil Moisture",
              value: "45%",
              icon: Icons.water_drop,
              color: Colors.blue,
            ),
            const SensorCard(
              title: "Temperature",
              value: "28°C",
              icon: Icons.thermostat,
              color: Colors.orange,
            ),
            const SensorCard(
              title: "Humidity",
              value: "70%",
              icon: Icons.cloud,
              color: Colors.cyan,
            ),
            IrrigationCard(
              isOn: irrigationOn,
              onPressed: () {
                setState(() {
                  irrigationOn = !irrigationOn;
                });
              },
            ),
            const GreenhouseCard(
              status: "Healthy",
            ),
          ],
        ),
      ),
    );
  }
}
