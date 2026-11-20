import 'package:flutter/material.dart';

class GreenhouseCard extends StatelessWidget {
  final String status;

  const GreenhouseCard({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(
              Icons.home_work,
              size: 42,
              color: Colors.green,
            ),
            const SizedBox(height: 10),
            const Text(
              'Greenhouse',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              status,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
