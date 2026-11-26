import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/farm_profile.dart';
import '../services/farm_service.dart';
import 'farm_edit_screen.dart';
import '../widgets/figma_icons.dart';

class FarmDetailScreen extends StatelessWidget {
  const FarmDetailScreen(
      {super.key, required this.farm, required this.service});
  final FarmProfile farm;
  final FarmService service;

  Future<void> _edit(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FarmEditScreen(service: service, existing: farm),
      ),
    );
    // The farm may have changed: pop back so the list reloads fresh instead
    // of patching this screen's local copy.
    if (changed == true && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    final location = farm.locationSummary;

    return Scaffold(
      appBar: AppBar(
        title: Text(farm.name),
        actions: [
          IconButton(
            onPressed: () => _edit(context),
            tooltip: 'Edit farm',
            icon: const FIcon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailRow(label: 'Crop type', value: farm.cropType),
          _DetailRow(label: 'Land size', value: farm.landSizeLabel),
          _DetailRow(
              label: 'Plantation date', value: df.format(farm.plantationDate)),
          _DetailRow(label: 'Soil type', value: farm.soilType),
          _DetailRow(label: 'Irrigation system', value: farm.irrigationSystem),
          _DetailRow(
              label: 'Location',
              value: location.isEmpty ? 'Not set' : location),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 140,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(
              child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
