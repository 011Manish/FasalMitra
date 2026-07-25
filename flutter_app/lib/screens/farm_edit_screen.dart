import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/farm_photo.dart';
import '../models/farm_profile.dart';
import '../services/farm_service.dart';
import '../services/photo_service.dart';

class FarmEditScreen extends StatefulWidget {
  const FarmEditScreen({
    super.key,
    required this.service,
    this.existing,
    this.attachPhoto,
  });
  final FarmService service;
  final FarmProfile? existing;
  final File? attachPhoto;

  @override
  State<FarmEditScreen> createState() => _FarmEditScreenState();
}

class _FarmEditScreenState extends State<FarmEditScreen> {
  final _form = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final _photoService = PhotoService(Supabase.instance.client);

  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _size = TextEditingController(
      text: widget.existing?.landSizeHectares.toString() ?? '');
  late final _location =
      TextEditingController(text: widget.existing?.locationLabel ?? '');

  late String _crop = widget.existing?.cropType ?? cropTypes.first;
  late String _soil = widget.existing?.soilType ?? soilTypes.first;
  late String _irrig =
      widget.existing?.irrigationSystem ?? irrigationSystems.first;
  late DateTime _plantedOn = widget.existing?.plantationDate ?? DateTime.now();

  // Only meaningful when editing a farm that already exists.
  late Future<FarmPhoto?> _currentPhoto =
      widget.existing == null ? Future.value(null) : _loadCurrentPhoto();

  bool _busy = false;

  Future<FarmPhoto?> _loadCurrentPhoto() async {
    final photos = await _photoService.listForFarm(widget.existing!.id);
    return photos.isEmpty ? null : photos.first;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate:
          _plantedOn.isAfter(DateTime.now()) ? DateTime.now() : _plantedOn,
    );
    if (picked != null) setState(() => _plantedOn = picked);
  }

  Future<void> _changePhoto() async {
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

    final picked =
        await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      await _photoService.upload(
          farmId: widget.existing!.id, file: File(picked.path));
      if (mounted) setState(() => _currentPhoto = _loadCurrentPhoto());
    } on PhotoTooLarge catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Photo upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);

    String? photoWarning;
    try {
      final size = double.parse(_size.text.trim());
      final farm = FarmProfile(
        id: widget.existing?.id ?? '',
        userId: '',
        name: _name.text.trim(),
        cropType: _crop,
        landSizeHectares: size,
        plantationDate: _plantedOn,
        soilType: _soil,
        irrigationSystem: _irrig,
        locationLabel:
            _location.text.trim().isEmpty ? null : _location.text.trim(),
      );

      if (widget.existing == null) {
        final created = await widget.service.create(farm);
        if (widget.attachPhoto != null) {
          try {
            await _photoService.upload(
                farmId: created.id, file: widget.attachPhoto!);
          } on PhotoTooLarge catch (e) {
            photoWarning = e.toString();
          } catch (e) {
            photoWarning =
                "Farm saved, but the photo couldn't be uploaded. You can add it later from the farm's photo screen.";
          }
        }
      } else {
        await widget.service.update(widget.existing!.id, {
          'name': farm.name,
          'crop_type': farm.cropType,
          'land_size_hectares': farm.landSizeHectares,
          'plantation_date':
              farm.plantationDate.toIso8601String().substring(0, 10),
          'soil_type': farm.soilType,
          'irrigation_system': farm.irrigationSystem,
          'location_label': farm.locationLabel,
        });
      }
      if (!mounted) return;
      if (photoWarning != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(photoWarning)));
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this farm?'),
        content: const Text('This will remove all its schedule items too.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await widget.service.delete(widget.existing!.id);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New farm' : 'Edit farm'),
        actions: [
          if (widget.existing != null)
            IconButton(
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              if (widget.attachPhoto != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    widget.attachPhoto!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This photo will be attached once the farm is saved.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],
              if (widget.existing != null) ...[
                FutureBuilder<FarmPhoto?>(
                  future: _currentPhoto,
                  builder: (context, snap) {
                    final photo = snap.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (photo != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FutureBuilder<String>(
                              future:
                                  _photoService.signedUrl(photo.storagePath),
                              builder: (context, urlSnap) {
                                if (!urlSnap.hasData) {
                                  return const SizedBox(
                                    height: 160,
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                return Image.network(urlSnap.data!,
                                    height: 160, fit: BoxFit.cover);
                              },
                            ),
                          )
                        else
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0x11000000),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(child: Text('No photo yet')),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _changePhoto,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(
                              photo == null ? 'Add photo' : 'Change photo'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ],
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Farm name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _crop,
                decoration: const InputDecoration(labelText: 'Crop type'),
                items: cropTypes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _crop = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _size,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Land size (hectares)'),
                validator: (v) {
                  final parsed = double.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed <= 0)
                    return 'Enter a positive number';
                  if (parsed > 10000) return 'Too large';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: 'Plantation date'),
                  child: Text(df.format(_plantedOn)),
                ),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _irrig,
                decoration:
                    const InputDecoration(labelText: 'Irrigation system'),
                items: irrigationSystems
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _irrig = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                    labelText: 'Location label (optional)'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(
                    widget.existing == null ? 'Create farm' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
