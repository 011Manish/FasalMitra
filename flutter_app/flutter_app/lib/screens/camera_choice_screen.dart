import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/farm_profile.dart';
import '../services/farm_service.dart';
import '../services/photo_service.dart';
import 'farm_edit_screen.dart';
import 'farm_photos_screen.dart';
import '../services/plant_scan_service.dart';
import 'plant_scan_history_screen.dart';
import 'plant_scan_result_screen.dart';

class CameraChoiceScreen extends StatefulWidget {
  const CameraChoiceScreen({super.key});

  @override
  State<CameraChoiceScreen> createState() => _CameraChoiceScreenState();
}

class _CameraChoiceScreenState extends State<CameraChoiceScreen> {
  late final _farms = FarmService(Supabase.instance.client);
  late final _photos = PhotoService(Supabase.instance.client);
  late final _scans = PlantScanService(Supabase.instance.client);
  final _picker = ImagePicker();

  bool _busy = false;

  Future<void> _addFarmPhoto() async {
    final source = await _pickSource();
    if (source == null) return;

    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) {
        setState(() => _busy = false);
        return;
      }
      final file = File(picked.path);

      final farms = await _farms.listMine();

      // No farms yet -> only option is creating one with this photo attached.
      // Otherwise ask whether it belongs to an existing farm or a new one.
      final target = farms.isEmpty ? _PhotoTarget.newFarm : await _pickTarget();
      if (target == null) return;

      if (target == _PhotoTarget.newFarm) {
        if (!mounted) return;
        setState(() => _busy = false);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FarmEditScreen(service: _farms, attachPhoto: file),
          ),
        );
        if (mounted) Navigator.pop(context);
        return;
      }

      final farm = farms.length == 1 ? farms.first : await _pickFarm(farms);
      if (farm == null) return;

      final saved = await _photos.upload(farmId: farm.id, file: file);
      if (!mounted) return;
      _snack('Photo saved to ${farm.name}.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FarmPhotosScreen(farm: farm, highlightPhotoId: saved.id),
        ),
      );
    } on PhotoTooLarge catch (e) {
      _snack(e.toString());
    } catch (e) {
      _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkPlantHealth() async {
    final farms = await _farms.listMine();
    if (farms.isEmpty) {
      _snack('Add a farm first so we know which field this photo is from.');
      return;
    }

    final source = await _pickSource();
    if (source == null) return;

    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      final file = File(picked.path);

      final farm = farms.length == 1 ? farms.first : await _pickFarm(farms);
      if (farm == null) return;

      final path = await _scans.uploadScanPhoto(farmId: farm.id, file: file);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PlantScanResultScreen.newScan(farmId: farm.id, storagePath: path),
        ),
      );
    } catch (e) {
      _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _viewPlantHealthHistory() async {
    final farms = await _farms.listMine();
    if (farms.isEmpty) {
      _snack('Add a farm first to see scan history.');
      return;
    }
    final farm = farms.length == 1 ? farms.first : await _pickFarm(farms);
    if (farm == null) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => PlantScanHistoryScreen(farm: farm, service: _scans)),
    );
  }

  Future<ImageSource?> _pickSource() {
    return showModalBottomSheet<ImageSource>(
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
  }

  Future<_PhotoTarget?> _pickTarget() {
    return showDialog<_PhotoTarget>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Where should this photo go?'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, _PhotoTarget.existingFarm),
            child: const ListTile(
              leading: Icon(Icons.grass),
              title: Text('Add to an existing farm'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, _PhotoTarget.newFarm),
            child: const ListTile(
              leading: Icon(Icons.add_circle_outline),
              title: Text('Create a new farm with this photo'),
            ),
          ),
        ],
      ),
    );
  }

  Future<FarmProfile?> _pickFarm(List<FarmProfile> farms) {
    return showDialog<FarmProfile>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Which farm is this photo for?'),
        children: farms
            .map((f) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, f),
                  child: Text('${f.name} — ${f.cropType}'),
                ))
            .toList(),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_a_photo_outlined, size: 32),
                title: const Text('Add farm photo'),
                subtitle:
                    const Text('Record what your field looks like today.'),
                trailing: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.chevron_right),
                onTap: _busy ? null : _addFarmPhoto,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_florist_outlined, size: 32),
                title: const Text('Check plant health'),
                subtitle:
                    const Text('Snap a photo for an instant AI health report.'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history),
                      tooltip: 'Past scans',
                      onPressed: _busy ? null : _viewPlantHealthHistory,
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: _busy ? null : _checkPlantHealth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PhotoTarget { existingFarm, newFarm }
