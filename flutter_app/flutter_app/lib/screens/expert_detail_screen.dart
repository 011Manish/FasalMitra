import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expert.dart';
import '../models/farm_profile.dart';
import '../services/consultation_service.dart';
import '../services/farm_service.dart';
import 'consultation_chat_screen.dart';

class ExpertDetailScreen extends StatefulWidget {
  const ExpertDetailScreen({super.key, required this.expert});
  final Expert expert;

  @override
  State<ExpertDetailScreen> createState() => _ExpertDetailScreenState();
}

class _ExpertDetailScreenState extends State<ExpertDetailScreen> {
  late final _service = ConsultationService(Supabase.instance.client);
  late final _farms = FarmService(Supabase.instance.client);
  bool _busy = false;

  Future<void> _request() async {
    setState(() => _busy = true);
    try {
      final farms = await _farms.listMine();
      FarmProfile? farm;
      if (farms.isNotEmpty) {
        farm = await _pickFarm(farms);
        // User dismissed the picker — treat as "no specific farm" rather than aborting.
      }
      final appt = await _service.requestAppointment(
        expertId: widget.expert.id,
        farmId: farm?.id,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConsultationChatScreen(
            appointmentId: appt.id,
            expertName: widget.expert.name,
          ),
        ),
      );
    } catch (e) {
      if (mounted) _snack('Could not request: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<FarmProfile?> _pickFarm(List<FarmProfile> farms) {
    return showDialog<FarmProfile>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Which farm is this consultation about?'),
        children: [
          ...farms.map((f) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, f),
                child: Text('${f.name} — ${f.cropType}'),
              )),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not about a specific farm'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.expert;
    return Scaffold(
      appBar: AppBar(title: Text(e.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage:
                    e.photoUrl != null ? NetworkImage(e.photoUrl!) : null,
                child: e.photoUrl == null
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: Theme.of(context).textTheme.titleLarge),
                    Text(e.specialty,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(e.bio, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _request,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chat_bubble_outline),
            label: const Text('Request consultation'),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: 'Video call — coming soon',
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Video call (coming soon)'),
            ),
          ),
        ],
      ),
    );
  }
}
