import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/farm_profile.dart';
import '../services/farm_service.dart';
import 'farm_edit_screen.dart';

class FarmsListScreen extends StatefulWidget {
  const FarmsListScreen({super.key, required this.service});
  final FarmService service;

  @override
  State<FarmsListScreen> createState() => _FarmsListScreenState();
}

class _FarmsListScreenState extends State<FarmsListScreen> {
  late Future<List<FarmProfile>> _load;

  @override
  void initState() {
    super.initState();
    _load = widget.service.listMine();
  }

  Future<void> _refresh() async {
    setState(() => _load = widget.service.listMine());
    await _load;
  }

  Future<void> _openEditor([FarmProfile? existing]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FarmEditScreen(service: widget.service, existing: existing)),
    );
    if (changed == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<FarmProfile>>(
          future: _load,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load farms: ${snap.error}'),
              )]);
            }
            final farms = snap.data ?? [];
            if (farms.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('No farm profiles yet.\nTap + to add one.',
                    textAlign: TextAlign.center)),
              ]);
            }
            return ListView.separated(
              itemCount: farms.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final f = farms[i];
                return ListTile(
                  title: Text(f.name),
                  subtitle: Text(
                    '${f.cropType} — ${f.landSizeHectares} ha — planted ${df.format(f.plantationDate)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openEditor(f),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
