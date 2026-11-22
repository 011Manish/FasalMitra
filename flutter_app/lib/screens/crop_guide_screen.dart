import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crop_info.dart';
import '../models/farm_profile.dart';
import '../services/crop_service.dart';

const _seasonLabels = {
  'monsoon': 'Monsoon (about Jun to Sep)',
  'winter': 'Winter (about Oct to Feb)',
  'spring': 'Spring (about Mar to May)',
};

const _disclaimer = 'General guidance only, not a guaranteed recommendation. '
    'Check with your local agriculture office before planting.';

class CropGuideScreen extends StatefulWidget {
  const CropGuideScreen({super.key});

  @override
  State<CropGuideScreen> createState() => _CropGuideScreenState();
}

class _CropGuideScreenState extends State<CropGuideScreen> {
  late final _service = CropService(Supabase.instance.client);
  late Future<List<CropInfo>> _crops = _service.listCrops();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Crop guide'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Crops'), Tab(text: 'Suggest')],
          ),
        ),
        body: FutureBuilder<List<CropInfo>>(
          future: _crops,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Could not load: ${snap.error}'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            setState(() => _crops = _service.listCrops()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final crops = snap.data!;
            if (crops.isEmpty) {
              return const Center(child: Text('No crop information yet.'));
            }
            return TabBarView(
              children: [
                _CropList(crops: crops),
                _SuggestTab(crops: crops),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CropList extends StatelessWidget {
  const _CropList({required this.crops});
  final List<CropInfo> crops;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: crops.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final c = crops[i];
        return ListTile(
          title: Text(c.nameNe == null ? c.name : '${c.name} (${c.nameNe})'),
          subtitle:
              Text('${c.seasons.join(', ')} • about ${c.durationDays} days'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CropDetailScreen(crop: c)),
          ),
        );
      },
    );
  }
}

class CropDetailScreen extends StatelessWidget {
  const CropDetailScreen({super.key, required this.crop});
  final CropInfo crop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(crop.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (crop.nameNe != null)
            Text(crop.nameNe!, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          _info('Seasons', crop.seasons.join(', ')),
          _info('Duration', 'About ${crop.durationDays} days'),
          _info('Water need', crop.waterNeed),
          _info('Suitable soils', crop.suitableSoils.join(', ')),
          const SizedBox(height: 16),
          Text('Growing steps', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < crop.growingSteps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${i + 1}. ${crop.growingSteps[i]}'),
            ),
          if (crop.notes != null) ...[
            const SizedBox(height: 16),
            Text(crop.notes!),
          ],
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                crop.isVerified
                    ? _disclaimer
                    : 'Placeholder guidance, not yet verified by an '
                        'agronomist. $_disclaimer',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(value.isEmpty ? '-' : value)),
          ],
        ),
      );
}

class _SuggestTab extends StatefulWidget {
  const _SuggestTab({required this.crops});
  final List<CropInfo> crops;

  @override
  State<_SuggestTab> createState() => _SuggestTabState();
}

class _SuggestTabState extends State<_SuggestTab> {
  late String _season = _currentSeason();
  String _soil = soilTypes.first;
  bool _irrigated = true;
  List<CropSuggestion>? _results;

  static String _currentSeason() {
    final m = DateTime.now().month;
    if (m >= 6 && m <= 9) return 'monsoon';
    if (m >= 3 && m <= 5) return 'spring';
    return 'winter';
  }

  void _run() {
    setState(() {
      _results = CropService.suggest(
        widget.crops,
        season: _season,
        soil: _soil,
        irrigated: _irrigated,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _results;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _season,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Season'),
          items: _seasonLabels.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => setState(() => _season = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _soil,
          decoration: const InputDecoration(labelText: 'Soil type'),
          items: soilTypes
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _soil = v!),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Irrigation or reliable water available'),
          value: _irrigated,
          onChanged: (v) => setState(() => _irrigated = v),
        ),
        const SizedBox(height: 8),
        FilledButton(onPressed: _run, child: const Text('Get suggestions')),
        const SizedBox(height: 16),
        if (results != null) ...[
          if (results.isEmpty)
            const Text('No matching crops found for these inputs.')
          else
            for (final s in results)
              Card(
                child: ListTile(
                  title: Text(s.crop.name),
                  subtitle: Text(s.reasons.join('\n')),
                  isThreeLine: true,
                  trailing: Text('${s.score}/5'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => CropDetailScreen(crop: s.crop)),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          Text(_disclaimer, style: theme.textTheme.bodySmall),
        ] else
          Text(_disclaimer, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
