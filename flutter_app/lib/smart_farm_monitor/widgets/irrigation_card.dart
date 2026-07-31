import 'package:flutter/material.dart';

class IrrigationCard extends StatelessWidget {
  final bool isOn;
  final VoidCallback onPressed;

  const IrrigationCard({
    super.key,
    required this.isOn,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.water_drop,
                size: 45,
                color: Colors.blue,
              ),
              const SizedBox(height: 10),
              const Text(
                'Automatic Irrigation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Switch(
                value: isOn,
                onChanged: (_) => onPressed(),
              ),
              Text(
                isOn ? 'ON' : 'OFF',
              )
            ],
          ),
        ),
      ),
    );
  }
}
