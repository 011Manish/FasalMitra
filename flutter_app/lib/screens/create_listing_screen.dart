import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import '../services/photo_service.dart' show maxPhotoBytes;

const _maxPhotos = 4;

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key, required this.service});
  final MarketplaceService service;

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _form = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _unit = TextEditingController(text: 'kg');
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _stateProvince = TextEditingController();
  final _district = TextEditingController();
  final _municipality = TextEditingController();

  DateTime _availableFrom = DateTime.now();
  final List<File> _photos = [];
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _unit,
      _quantity,
      _price,
      _stateProvince,
      _district,
      _municipality,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _textOrNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _availableFrom,
    );
    if (picked != null) setState(() => _availableFrom = picked);
  }

  Future<void> _addPhotos() async {
    if (_photos.length >= _maxPhotos) {
      _snack('You can add up to $_maxPhotos photos.');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pick from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = <XFile>[];
    if (source == ImageSource.camera) {
      final x = await _picker.pickImage(source: source, imageQuality: 85);
      if (x != null) picked.add(x);
    } else {
      picked.addAll(await _picker.pickMultiImage(imageQuality: 85));
    }

    final room = _maxPhotos - _photos.length;
    final added = <File>[];
    var tooBig = 0;
    for (final x in picked.take(room)) {
      final f = File(x.path);
      if (await f.length() > maxPhotoBytes) {
        tooBig++;
      } else {
        added.add(f);
      }
    }
    if (!mounted) return;
    setState(() => _photos.addAll(added));
    if (tooBig > 0) _snack('$tooBig photo(s) skipped: each must be under 5 MB.');
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final listing = MarketplaceListing(
        id: '',
        sellerId: '',
        title: _title.text.trim(),
        description: _textOrNull(_description),
        unit: _unit.text.trim(),
        quantity: double.parse(_quantity.text.trim()),
        price: double.parse(_price.text.trim()),
        createdAt: DateTime.now(),
        stateProvince: _textOrNull(_stateProvince),
        district: _textOrNull(_district),
        municipality: _textOrNull(_municipality),
        availableFrom: _availableFrom,
      );
      final created = await widget.service.create(listing);

      var failed = 0;
      for (final f in _photos) {
        try {
          await widget.service.uploadPhoto(listingId: created.id, file: f);
        } catch (_) {
          failed++;
        }
      }
      if (!mounted) return;
      if (failed > 0) {
        _snack('Listing published, but $failed photo(s) could not be uploaded.');
      }
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Could not create listing: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: const Text('Sell produce')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Crop name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantity,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (v) {
                        final p = double.tryParse(v?.trim() ?? '');
                        if (p == null || p <= 0) return 'Enter a positive number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unit,
                      decoration:
                          const InputDecoration(labelText: 'Unit (kg, bag...)'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Asking price per unit (NPR)'),
                validator: (v) {
                  final p = double.tryParse(v?.trim() ?? '');
                  if (p == null || p <= 0) return 'Enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Harvest / available from'),
                  child: Text(df.format(_availableFrom)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _district,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'District'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _municipality,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Municipality / Village (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stateProvince,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'State / Province (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 16),
              Text('Photos (${_photos.length}/$_maxPhotos)',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _photos.length; i++)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_photos[i],
                              width: 88, height: 88, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => setState(() => _photos.removeAt(i)),
                            child: const CircleAvatar(
                              radius: 12,
                              child: Icon(Icons.close, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_photos.length < _maxPhotos)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _addPhotos,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Add photos'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Publishing...' : 'Publish listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}