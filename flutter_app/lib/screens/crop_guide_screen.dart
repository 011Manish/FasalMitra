import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crop_info.dart';
import '../services/crop_service.dart';
import 'crop_detail_screen.dart';
import 'crop_suggestion_screen.dart';

class CropGuideScreen extends StatefulWidget {
  const CropGuideScreen({super.key, this.farmDistrict});
  final String? farmDistrict;

  @override
  State<CropGuideScreen> createState() => _CropGuideScreenState();
}

class _CropGuideScreenState extends State<CropGuideScreen> {
  late final _service = CropService(Supabase.instance.client);
  late Future<List<CropInfo>> _crops = _service.listCrops();

  void _reload() => setState(() => _crops = _service.listCrops());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop guide')),
      body: FutureBuilder<List<CropInfo>>(
        future: _crops,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return _LoadError(onRetry: _reload);
          final crops = snap.data ?? const <CropInfo>[];
          if (crops.isEmpty) {
            return const Center(child: Text('No crop information yet.'));
          }
          return _CropList(crops: crops, farmDistrict: widget.farmDistrict);
        },
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(cropLoadError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _CropList extends StatelessWidget {
  const _CropList({required this.crops, required this.farmDistrict});
  final List<CropInfo> crops;
  final String? farmDistrict;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: ListTile(
            leading: const Icon(Icons.agriculture_outlined),
            title: const Text('Which crop suits my land?'),
            subtitle: const Text('Choose season, soil and water'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CropSuggestionScreen(
                    crops: crops, farmDistrict: farmDistrict),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(guidanceDisclaimer,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        for (final crop in crops) ...[
          _CropTile(crop: crop),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

class _CropTile extends StatelessWidget {
  const _CropTile({required this.crop});
  final CropInfo crop;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(crop.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (crop.nameNe case final String nameNe when nameNe.isNotEmpty)
            Text(nameNe),
          Text('${crop.seasonsText} • ${crop.durationText}'),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CropDetailScreen(crop: crop)),
      ),
    );
  }
}
