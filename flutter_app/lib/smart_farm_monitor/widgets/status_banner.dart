import 'package:flutter/material.dart';

class StatusBanner extends StatelessWidget {
  final bool isLive;

  const StatusBanner({
    super.key,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    final Color background =
        isLive ? Colors.green.shade50 : Colors.orange.shade50;

    final Color iconColor =
        isLive ? Colors.green.shade700 : Colors.orange.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: iconColor.withOpacity(.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLive ? Icons.wifi : Icons.wifi_off,
            color: iconColor,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLive ? 'Sensors Connected' : 'Sensors Offline',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLive
                      ? 'Receiving live sensor readings.'
                      : 'Connect your ESP32 to start monitoring.',
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
