import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/farm_profile.dart';
import '../services/farm_service.dart';
import 'crop_guide_screen.dart';
import 'farm_detail_screen.dart';
import 'farm_edit_screen.dart';
import '../l10n/app_lang.dart';
import '../widgets/figma_icons.dart';

class FarmsListScreen extends StatefulWidget {
  const FarmsListScreen({super.key, required this.service});
  final FarmService service;

  @override
  State<FarmsListScreen> createState() => _FarmsListScreenState();
}

class _FarmsListScreenState extends State<FarmsListScreen> {
  late Future<List<FarmProfile>> _load;
  String? _firstDistrict;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<FarmProfile>> _fetch() async {
    final farms = await widget.service.listMine();
    _firstDistrict = farms.isEmpty ? null : farms.first.district;
    return farms;
  }

  Future<void> _refresh() async {
    final next = _fetch();
    setState(() => _load = next);
    try {
      await next;
    } catch (_) {
      // Not rethrown: the FutureBuilder below shows the error state.
    }
  }

  void _openCropGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => CropGuideScreen(farmDistrict: _firstDistrict)),
    );
  }

  Future<void> _openEditor() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => FarmEditScreen(service: widget.service)),
    );
    if (changed == true) _refresh();
  }

  Future<void> _openDetail(FarmProfile farm) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) =>
              FarmDetailScreen(farm: farm, service: widget.service)),
    );
    if (changed == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: ListTile(
              leading: const FIcon(Icons.eco_outlined),
              title: Text(tr('Crop guide')),
              subtitle: Text(tr('Crop information and suggestions')),
              trailing: const FIcon(Icons.chevron_right),
              onTap: _openCropGuide,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<FarmProfile>>(
                future: _load,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 96),
                        const Text('Could not load farms. Check your internet.',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Center(
                          child: FilledButton(
                              onPressed: _refresh, child: const Text('Retry')),
                        ),
                      ],
                    );
                  }
                  final farms = snap.data ?? [];
                  if (farms.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 120),
                      Center(
                          child: Text(
                              'No farm profiles yet.\nTap + to add one.',
                              textAlign: TextAlign.center)),
                    ]);
                  }
                  return ListView.separated(
                    itemCount: farms.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final f = farms[i];
                      return ListTile(
                        leading: const CircleAvatar(child: FIcon(Icons.grass)),
                        title: Text(f.name),
                        subtitle: Text(
                          '${f.cropType} — ${f.landSizeLabel} — planted ${df.format(f.plantationDate)}',
                        ),
                        trailing: const FIcon(Icons.chevron_right),
                        onTap: () => _openDetail(f),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addFarmButton',
        onPressed: _openEditor,
        tooltip: tr('Add a farm'),
        child: const FIcon(Icons.add),
      ),
    );
  }
}
