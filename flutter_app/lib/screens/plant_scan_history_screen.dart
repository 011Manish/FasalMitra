import 'package:flutter/material.dart';

import '../models/plant_scan.dart';
import '../services/plant_scan_service.dart';
import 'plant_scan_result_screen.dart';

class PlantScanHistoryScreen extends StatefulWidget {
  const PlantScanHistoryScreen({super.key, required this.service});
  final PlantScanService service;

  @override
  State<PlantScanHistoryScreen> createState() => _PlantScanHistoryScreenState();
}

class _PlantScanHistoryScreenState extends State<PlantScanHistoryScreen> {
  late final _future = widget.service.listMine();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan history')),
      body: FutureBuilder<List<PlantScan>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Could not load history. Check your internet.'));
          }
          final scans = snapshot.data!;
          if (scans.isEmpty) {
            return const Center(child: Text('No scans yet.'));
          }
          return ListView.builder(
            itemCount: scans.length,
            itemBuilder: (context, i) {
              final scan = scans[i];
              final score = scan.analysis['health_score'];
              return ListTile(
                leading: CircleAvatar(
                  child: score is num
                      ? Text('${score.round()}')
                      : const Icon(Icons.search),
                ),
                title: Text(
                  (scan.analysis['summary'] ?? 'Scan').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(scan.createdAt.toLocal().toString()),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlantScanResultScreen.existing(scan: scan),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
