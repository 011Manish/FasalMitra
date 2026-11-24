import 'package:flutter/material.dart';

import '../models/crop_info.dart';

class CropDetailScreen extends StatelessWidget {
  const CropDetailScreen({super.key, required this.crop});
  final CropInfo crop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameNe = crop.nameNe;
    final notes = crop.notes;
    return Scaffold(
      appBar: AppBar(title: Text(crop.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (nameNe != null && nameNe.isNotEmpty)
            Text(nameNe, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          _InfoRow(label: 'Seasons', value: crop.seasonsText),
          _InfoRow(label: 'Duration', value: crop.durationText),
          _InfoRow(label: 'Water need', value: capitalized(crop.waterNeed)),
          _InfoRow(label: 'Suitable soils', value: crop.soilsText),
          const SizedBox(height: 16),
          Text('Growing steps', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (crop.growingSteps.isEmpty)
            const Text('No growing steps added yet.')
          else
            for (var i = 0; i < crop.growingSteps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${i + 1}. ${crop.growingSteps[i]}'),
              ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(notes),
          ],
          const SizedBox(height: 24),
          if (!crop.isVerified)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child:
                    Text(unverifiedNotice, style: theme.textTheme.bodyMedium),
              ),
            ),
          const SizedBox(height: 8),
          Text(guidanceDisclaimer, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}
