import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/rental_equipment.dart';
import '../services/equipment_rental_service.dart';
import 'equipment_detail_screen.dart';
import 'my_equipment_bookings_screen.dart';

class EquipmentRentalScreen extends StatefulWidget {
  const EquipmentRentalScreen({super.key});

  @override
  State<EquipmentRentalScreen> createState() => _EquipmentRentalScreenState();
}

class _EquipmentRentalScreenState extends State<EquipmentRentalScreen> {
  late final _service = EquipmentRentalService(Supabase.instance.client);
  late Future<List<RentalEquipment>> _load;
  String? _category;

  static const _categories = ['Tractor', 'Harvester', 'Sprayer', 'Irrigation'];

  @override
  void initState() {
    super.initState();
    _load = _service.listEquipment();
  }

  Future<void> _refresh() async {
    setState(() => _load = _service.listEquipment(category: _category));
    await _load;
  }

  void _pick(String? c) {
    setState(() {
      _category = c;
      _load = _service.listEquipment(category: c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rs =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment rental'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'My bookings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyEquipmentBookingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _category == null,
                    onSelected: (_) => _pick(null),
                  ),
                ),
                for (final c in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => _pick(c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<RentalEquipment>>(
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
                  final items = snap.data!;
                  if (items.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No equipment listed yet.')),
                    ]);
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = items[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: e.photoUrl != null
                              ? NetworkImage(e.photoUrl!)
                              : null,
                          child: e.photoUrl == null
                              ? const Icon(Icons.agriculture_outlined)
                              : null,
                        ),
                        title: Text(e.name),
                        subtitle: Text(
                          '${e.category} • ${rs.format(e.dailyRate)}/day'
                          '${e.providerName != null ? '\n${e.providerName}' : ''}',
                        ),
                        isThreeLine: e.providerName != null,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EquipmentDetailScreen(equipment: e),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
