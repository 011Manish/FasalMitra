import 'package:flutter/material.dart';

import '../models/farm_profile.dart';
import '../models/plant_scan.dart';
import '../services/plant_scan_service.dart';
import 'plant_scan_result_screen.dart';

class PlantScanHistoryScreen extends StatefulWidget {
  const PlantScanHistoryScreen(
      {super.key, required this.farm, required this.service});
  final FarmProfile farm;
  final PlantScanService service;

  @override
  State<PlantScanHistoryScreen> createState() => _PlantScanHistoryScreenState();
}

class _PlantScanHistoryScreenState extends State<PlantScanHistoryScreen> {
  late final _future = widget.service.listForFarm(widget.farm.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.farm.name} — scan history')),
      body: FutureBuilder<List<PlantScan>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Couldn\'t load history: ${snapshot.error}'));
          }
          final scans = snapshot.data!;
          if (scans.isEmpty) {
            return const Center(child: Text('No scans yet for this farm.'));
          }
          return ListView.builder(
            itemCount: scans.length,
            itemBuilder: (context, i) {
              final scan = scans[i];
              final score = scan.analysis['health_score'] as int? ?? 0;
              return ListTile(
                leading: CircleAvatar(child: Text('$score')),
                title: Text((scan.analysis['summary'] ?? 'Scan').toString()),
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
