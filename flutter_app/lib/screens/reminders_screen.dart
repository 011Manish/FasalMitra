import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/farm_profile.dart';
import '../services/farm_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, required this.service});
  final FarmService service;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late Future<List<ScheduleItem>> _load;

  @override
  void initState() {
    super.initState();
    _load = widget.service.reminders();
  }

  Future<void> _refresh() async {
    setState(() => _load = widget.service.reminders());
    await _load;
  }

  Future<void> _mark(ScheduleItem it, String status) async {
    await widget.service.markScheduleItem(it.id, status);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfToday = DateTime.utc(today.year, today.month, today.day);
    final df = DateFormat.yMMMd();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<ScheduleItem>>(
        future: _load,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ListView(children: [Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load reminders: ${snap.error}'),
            )]);
          }
          final all = snap.data ?? [];
          final overdue = all.where((it) => it.dueDate.isBefore(startOfToday)).toList();
          final dueToday = all.where((it) => !it.dueDate.isBefore(startOfToday)).toList();

          if (all.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 120),
              Center(child: Text('Nothing due today. Nice.')),
            ]);
          }

          return ListView(
            children: [
              if (overdue.isNotEmpty) _sectionHeader(context, 'Overdue', Colors.red),
              ...overdue.map((it) => _tile(it, df, overdue: true)),
              if (dueToday.isNotEmpty) _sectionHeader(context, 'Due today', Colors.orange),
              ...dueToday.map((it) => _tile(it, df, overdue: false)),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
      ),
    );
  }

  Widget _tile(ScheduleItem it, DateFormat df, {required bool overdue}) {
    return ListTile(
      leading: Icon(_iconFor(it.kind), color: overdue ? Colors.red : null),
      title: Text(it.title),
      subtitle: Text('Due ${df.format(it.dueDate)}'),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => _mark(it, v),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'done', child: Text('Mark done')),
          PopupMenuItem(value: 'skipped', child: Text('Skip')),
        ],
      ),
    );
  }

  IconData _iconFor(String kind) {
    switch (kind) {
      case 'watering': return Icons.water_drop_outlined;
      case 'fertilizer': return Icons.eco_outlined;
      case 'harvest': return Icons.agriculture_outlined;
      default: return Icons.event_note_outlined;
    }
  }
}
