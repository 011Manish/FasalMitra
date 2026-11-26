import 'package:flutter/material.dart';

import '../models/crop_info.dart';
import '../models/farm_profile.dart' show soilTypes;
import 'crop_detail_screen.dart';
import '../widgets/figma_icons.dart';

class CropSuggestionScreen extends StatefulWidget {
  const CropSuggestionScreen(
      {super.key, required this.crops, this.farmDistrict});
  final List<CropInfo> crops;
  final String? farmDistrict;

  @override
  State<CropSuggestionScreen> createState() => _CropSuggestionScreenState();
}

class _CropSuggestionScreenState extends State<CropSuggestionScreen> {
  String? _season;
  String? _soil;
  String? _water;
  List<CropMatch>? _results;

  bool get _ready => _season != null && _soil != null && _water != null;

  void _suggest() {
    setState(() {
      _results = suggestCrops(
        widget.crops,
        season: _season!,
        soil: _soil!,
        water: _water!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final district = widget.farmDistrict?.trim();
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: const Text('Crop suggestions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tell us about your land', style: theme.textTheme.titleMedium),
          if (district != null && district.isNotEmpty)
            Text('Your farm district: $district (not used to filter crops)',
                style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          _ChoiceField(
            label: 'Season',
            options: cropSeasons,
            value: _season,
            onChanged: (v) => setState(() {
              _season = v;
              _results = null;
            }),
          ),
          const SizedBox(height: 12),
          _ChoiceField(
            label: 'Soil type',
            options: soilTypes,
            value: _soil,
            onChanged: (v) => setState(() {
              _soil = v;
              _results = null;
            }),
          ),
          const SizedBox(height: 12),
          _ChoiceField(
            label: 'Water availability',
            options: waterLevels,
            value: _water,
            onChanged: (v) => setState(() {
              _water = v;
              _results = null;
            }),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _ready ? _suggest : null,
            child: const Text('Suggest crops'),
          ),
          const SizedBox(height: 16),
          if (results != null) ...[
            if (results.isEmpty)
              const Text('No crop in our list matches these inputs.')
            else
              for (final match in results)
                Card(
                  child: ListTile(
                    title: Text(match.crop.name),
                    subtitle: Text(match.reasons.join('\n')),
                    isThreeLine: true,
                    trailing: const FIcon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CropDetailScreen(crop: match.crop),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 12),
          ],
          Text(guidanceDisclaimer, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      hint: const Text('Choose one'),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(capitalized(option))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
