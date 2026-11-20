import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/farm_income_entry.dart';
import '../models/farm_profile.dart';
import '../models/finance_info.dart';
import '../services/farm_service.dart';
import '../services/finance_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  late final _finance = FinanceService(Supabase.instance.client);
  late final _farms = FarmService(Supabase.instance.client);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Info'),
            Tab(text: 'Income'),
          ]),
        ),
        body: TabBarView(children: [
          _InfoTab(service: _finance),
          _IncomeTab(finance: _finance, farms: _farms),
        ]),
      ),
    );
  }
}

class _InfoTab extends StatefulWidget {
  const _InfoTab({required this.service});
  final FinanceService service;

  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  late Future<List<FinanceInfo>> _load;

  @override
  void initState() {
    super.initState();
    _load = widget.service.listFinanceInfo();
  }

  Future<void> _refresh() async {
    setState(() => _load = widget.service.listFinanceInfo());
    await _load;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<FinanceInfo>>(
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
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 120),
              Center(child: Text('Nothing here yet.')),
            ]);
          }

          final grouped = <String, List<FinanceInfo>>{};
          for (final it in items) {
            grouped.putIfAbsent(it.category, () => []).add(it);
          }
          final order = financeCategories.where(grouped.containsKey).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final cat in order) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    _label(cat),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                for (final it in grouped[cat]!)
                  ListTile(
                    title: Text(it.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => _InfoDetailScreen(item: it)),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _label(String cat) => switch (cat) {
        'insurance' => 'Insurance',
        'loan' => 'Loans',
        'subsidy' => 'Subsidies',
        _ => cat,
      };
}

class _InfoDetailScreen extends StatelessWidget {
  const _InfoDetailScreen({required this.item});
  final FinanceInfo item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(item.body, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

class _IncomeTab extends StatefulWidget {
  const _IncomeTab({required this.finance, required this.farms});
  final FinanceService finance;
  final FarmService farms;

  @override
  State<_IncomeTab> createState() => _IncomeTabState();
}

class _IncomeTabState extends State<_IncomeTab> {
  FarmProfile? _farm;
  Future<List<FarmIncomeEntry>>? _load;

  Future<void> _chooseFarm() async {
    final farms = await widget.farms.listMine();
    if (!mounted) return;
    if (farms.isEmpty) {
      _snack('Add a farm first to track its income.');
      return;
    }
    final picked = farms.length == 1 ? farms.first : await _pickFarm(farms);
    if (picked == null) return;
    setState(() {
      _farm = picked;
      _load = widget.finance.listIncomeEntries(picked.id);
    });
  }

  Future<FarmProfile?> _pickFarm(List<FarmProfile> farms) {
    return showDialog<FarmProfile>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Which farm?'),
        children: farms
            .map((f) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, f),
                  child: Text('${f.name} — ${f.cropType}'),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _refresh() async {
    if (_farm == null) return;
    setState(() => _load = widget.finance.listIncomeEntries(_farm!.id));
    await _load;
  }

  Future<void> _addEntry() async {
    final farm = _farm;
    if (farm == null) return;
    final added = await showDialog<FarmIncomeEntry>(
      context: context,
      builder: (_) => _AddEntryDialog(service: widget.finance, farmId: farm.id),
    );
    if (added != null) _refresh();
  }

  Future<void> _confirmDelete(FarmIncomeEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
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
    await widget.finance.deleteIncomeEntry(e.id);
    _refresh();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_farm == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pick a farm to view or add income entries.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _chooseFarm,
                icon: const Icon(Icons.grass),
                label: const Text('Choose farm'),
              ),
            ],
          ),
        ),
      );
    }

    final df = DateFormat.yMMMd();
    final money = NumberFormat.decimalPattern();

    return Scaffold(
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.grass),
            title: Text(_farm!.name),
            subtitle: Text(_farm!.cropType),
            trailing:
                TextButton(onPressed: _chooseFarm, child: const Text('Change')),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<FarmIncomeEntry>>(
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
                  final entries = snap.data ?? [];
                  if (entries.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 120),
                      Center(
                          child: Text('No income entries yet for this farm.')),
                    ]);
                  }
                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return ListTile(
                        title: Text(e.description),
                        subtitle: Text(df.format(e.entryDate)),
                        trailing: Text('NPR ${money.format(e.amount)}'),
                        onLongPress: () => _confirmDelete(e),
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
        heroTag: 'addIncomeEntry',
        onPressed: _addEntry,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddEntryDialog extends StatefulWidget {
  const _AddEntryDialog({required this.service, required this.farmId});
  final FinanceService service;
  final String farmId;

  @override
  State<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<_AddEntryDialog> {
  final _desc = TextEditingController();
  final _amount = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _desc.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final desc = _desc.text.trim();
    final amount = double.tryParse(_amount.text.trim());
    if (desc.isEmpty || amount == null) return;
    setState(() => _saving = true);
    final saved = await widget.service.addIncomeEntry(
      farmId: widget.farmId,
      description: desc,
      amount: amount,
      entryDate: _date,
    );
    if (!mounted) return;
    Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    return AlertDialog(
      title: const Text('Add income entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _desc,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          TextField(
            controller: _amount,
            decoration: const InputDecoration(labelText: 'Amount (NPR)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(df.format(_date))),
              TextButton(
                  onPressed: _pickDate, child: const Text('Change date')),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
