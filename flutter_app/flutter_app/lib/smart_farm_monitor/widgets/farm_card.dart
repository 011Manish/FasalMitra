import 'package:flutter/material.dart';

class FarmCard extends StatelessWidget {
  final String farmName;
  final String location;
  final String status;
  final VoidCallback onTap;

  const FarmCard({
    super.key,
    required this.farmName,
    required this.location,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = status.toLowerCase() == 'online';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.green.shade100,
          child: const Icon(
            Icons.agriculture,
            color: Colors.green,
          ),
        ),
        title: Text(
          farmName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(location),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.circle,
              color: isOnline ? Colors.green : Colors.red,
              size: 12,
            ),
            const SizedBox(height: 4),
            Text(status),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
