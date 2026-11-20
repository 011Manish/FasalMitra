import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/farm_photo.dart';
import '../models/farm_profile.dart';
import '../services/farm_service.dart';
import '../services/photo_service.dart';
import 'farm_edit_screen.dart';
import 'farm_photos_screen.dart';

class FarmDetailScreen extends StatefulWidget {
  const FarmDetailScreen(
      {super.key, required this.farm, required this.service});
  final FarmProfile farm;
  final FarmService service;

  @override
  State<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  late final _photos = PhotoService(Supabase.instance.client);
  late final Future<FarmPhoto?> _latestPhoto = _loadLatestPhoto();

  Future<FarmPhoto?> _loadLatestPhoto() async {
    final photos = await _photos.listForFarm(widget.farm.id);
    return photos.isEmpty ? null : photos.first;
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            FarmEditScreen(service: widget.service, existing: widget.farm),
      ),
    );
    // Farm fields or photo may have changed — simplest is to pop back to the
    // list so it reloads fresh, rather than trying to patch our local copy.
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  void _viewAllPhotos() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FarmPhotosScreen(farm: widget.farm)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    final farm = widget.farm;

    return Scaffold(
      appBar: AppBar(
        title: Text(farm.name),
        actions: [
          IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
      body: ListView(
        children: [
          FutureBuilder<FarmPhoto?>(
            future: _latestPhoto,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final photo = snap.data;
              if (photo == null) {
                return Container(
                  height: 220,
                  color: const Color(0x11000000),
                  child: const Center(child: Text('No photo yet')),
                );
              }
              return GestureDetector(
                onTap: _viewAllPhotos,
                child: FutureBuilder<String>(
                  future: _photos.signedUrl(photo.storagePath),
                  builder: (context, urlSnap) {
                    if (!urlSnap.hasData) {
                      return const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return Image.network(
                      urlSnap.data!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Crop type', value: farm.cropType),
                _DetailRow(
                    label: 'Land size', value: '${farm.landSizeHectares} ha'),
                _DetailRow(
                    label: 'Plantation date',
                    value: df.format(farm.plantationDate)),
                _DetailRow(label: 'Soil type', value: farm.soilType),
                _DetailRow(
                    label: 'Irrigation system', value: farm.irrigationSystem),
                if (farm.locationLabel != null)
                  _DetailRow(label: 'Location', value: farm.locationLabel!),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _viewAllPhotos,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('View all photos'),
                ),
              ],
            ),
          ),
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
