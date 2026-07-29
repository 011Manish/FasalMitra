import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expert.dart';
import '../services/consultation_service.dart';
import 'consultation_appointments_screen.dart';
import 'expert_detail_screen.dart';

class ExpertsListScreen extends StatefulWidget {
  const ExpertsListScreen({super.key});

  @override
  State<ExpertsListScreen> createState() => _ExpertsListScreenState();
}

class _ExpertsListScreenState extends State<ExpertsListScreen> {
  late final _service = ConsultationService(Supabase.instance.client);
  late Future<List<Expert>> _load;

  @override
  void initState() {
    super.initState();
    _load = _service.listExperts();
  }

  Future<void> _refresh() async {
    setState(() => _load = _service.listExperts());
    await _load;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note_outlined),
            tooltip: 'My appointments',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ConsultationAppointmentsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Expert>>(
          future: _load,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load experts: ${snap.error}'),
                )
              ]);
            }
            final experts = snap.data ?? [];
            if (experts.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('No experts available yet.')),
              ]);
            }
            return ListView.separated(
              itemCount: experts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = experts[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        e.photoUrl != null ? NetworkImage(e.photoUrl!) : null,
                    child: e.photoUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(e.name),
                  subtitle: Text(e.specialty),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => ExpertDetailScreen(expert: e)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
