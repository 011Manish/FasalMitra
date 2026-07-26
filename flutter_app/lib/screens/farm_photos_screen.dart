import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/farm_photo.dart';
import '../models/farm_profile.dart';
import '../services/photo_service.dart';

class FarmPhotosScreen extends StatefulWidget {
  const FarmPhotosScreen({super.key, required this.farm, this.highlightPhotoId});
  final FarmProfile farm;
  final String? highlightPhotoId;

  @override
  State<FarmPhotosScreen> createState() => _FarmPhotosScreenState();
}

class _FarmPhotosScreenState extends State<FarmPhotosScreen> {
  late final _photos = PhotoService(Supabase.instance.client);
  late Future<List<FarmPhoto>> _load;

  @override
  void initState() {
    super.initState();
    _load = _photos.listForFarm(widget.farm.id);
  }

  Future<void> _refresh() async {
    setState(() => _load = _photos.listForFarm(widget.farm.id));
    await _load;
  }

  Future<void> _confirmDelete(FarmPhoto photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _photos.delete(photo);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.farm.name} — photos')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<FarmPhoto>>(
          future: _load,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load photos: ${snap.error}'),
              )]);
            }
            final photos = snap.data ?? [];
            if (photos.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('No photos yet for this farm.')),
              ]);
            }
            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: photos.length,
              itemBuilder: (_, i) {
                final p = photos[i];
                final highlighted = p.id == widget.highlightPhotoId;
                return _PhotoTile(
                  photo: p,
                  loader: _photos.signedUrl,
                  captionDate: df.format(p.takenAt.toLocal()),
                  highlighted: highlighted,
                  onLongPress: () => _confirmDelete(p),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PhotoTile extends StatefulWidget {
  const _PhotoTile({
    required this.photo,
    required this.loader,
    required this.captionDate,
    required this.highlighted,
    required this.onLongPress,
  });

  final FarmPhoto photo;
  final Future<String> Function(String storagePath) loader;
  final String captionDate;
  final bool highlighted;
  final VoidCallback onLongPress;

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  late Future<String> _url;

  @override
  void initState() {
    super.initState();
    _url = widget.loader(widget.photo.storagePath);
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.highlighted
        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
        : null;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FutureBuilder<String>(
                future: _url,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const ColoredBox(
                      color: Color(0x11000000),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Image.network(snap.data!, fit: BoxFit.cover);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(widget.captionDate, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
