import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/consultation_appointment.dart';
import '../models/expert.dart';
import '../services/consultation_service.dart';
import 'consultation_chat_screen.dart';

class ConsultationAppointmentsScreen extends StatefulWidget {
  const ConsultationAppointmentsScreen({super.key});

  @override
  State<ConsultationAppointmentsScreen> createState() =>
      _ConsultationAppointmentsScreenState();
}

class _ConsultationAppointmentsScreenState
    extends State<ConsultationAppointmentsScreen> {
  late final _service = ConsultationService(Supabase.instance.client);
  late Future<_AppointmentsView> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<_AppointmentsView> _fetch() async {
    final appts = await _service.listMyAppointments();
    final experts = {for (final e in await _service.listExperts()) e.id: e};
    return _AppointmentsView(appts, experts);
  }

  Future<void> _refresh() async {
    setState(() => _load = _fetch());
    await _load;
  }

  Future<void> _cancel(ConsultationAppointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this appointment?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel it'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.cancelAppointment(a.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: const Text('My appointments')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_AppointmentsView>(
          future: _load,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load: ${snap.error}'),
                )
              ]);
            }
            final view = snap.data!;
            if (view.appts.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('No consultations yet.')),
              ]);
            }
            return ListView.separated(
              itemCount: view.appts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final a = view.appts[i];
                final expert = view.experts[a.expertId];
                final when = a.scheduledFor ?? a.requestedAt;
                return ListTile(
                  title: Text(expert?.name ?? 'Expert'),
                  subtitle: Text(
                    '${expert?.specialty ?? ''}\n${df.format(when.toLocal())} • ${a.status}',
                  ),
                  isThreeLine: true,
                  trailing: a.status == 'cancelled' || a.status == 'completed'
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Cancel',
                          onPressed: () => _cancel(a),
                        ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ConsultationChatScreen(
                        appointmentId: a.id,
                        expertName: expert?.name ?? 'Expert',
                      ),
                    ),
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

class _AppointmentsView {
  _AppointmentsView(this.appts, this.experts);
  final List<ConsultationAppointment> appts;
  final Map<String, Expert> experts;
}
