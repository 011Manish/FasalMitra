import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/plant_scan_service.dart';
import 'plant_scan_history_screen.dart';
import 'plant_scan_result_screen.dart';

class CameraChoiceScreen extends StatefulWidget {
  const CameraChoiceScreen({super.key});

  @override
  State<CameraChoiceScreen> createState() => _CameraChoiceScreenState();
}

class _CameraChoiceScreenState extends State<CameraChoiceScreen> {
  late final _scans = PlantScanService(Supabase.instance.client);
  final _picker = ImagePicker();

  bool _busy = false;

  Future<void> _scanPlant() async {
    final source = await _pickSource();
    if (source == null) return;

    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final path = await _scans.uploadScanPhoto(file: File(picked.path));
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlantScanResultScreen.newScan(storagePath: path),
        ),
      );
    } catch (_) {
      _snack('Upload failed. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _viewHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => PlantScanHistoryScreen(service: _scans)),
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Scan')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_florist_outlined, size: 32),
                title: const Text('Scan a plant photo'),
                subtitle: const Text(
                    'Take or choose a crop or leaf photo for an AI health report.'),
                trailing: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.history),
                            tooltip: 'Past scans',
                            onPressed: _viewHistory,
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                onTap: _busy ? null : _scanPlant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
