import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/equipment_booking.dart';
import '../models/rental_equipment.dart';
import '../services/equipment_rental_service.dart';

class MyEquipmentBookingsScreen extends StatefulWidget {
  const MyEquipmentBookingsScreen({super.key});

  @override
  State<MyEquipmentBookingsScreen> createState() =>
      _MyEquipmentBookingsScreenState();
}

class _MyEquipmentBookingsScreenState extends State<MyEquipmentBookingsScreen> {
  late final _service = EquipmentRentalService(Supabase.instance.client);
  late Future<_BookingsView> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<_BookingsView> _fetch() async {
    final bookings = await _service.listMyBookings();
    final equipment = {
      for (final e in await _service.listEquipment()) e.id: e,
    };
    return _BookingsView(bookings, equipment);
  }

  Future<void> _refresh() async {
    setState(() => _load = _fetch());
    await _load;
  }

  Future<void> _cancel(EquipmentBooking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this booking?'),
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
    await _service.cancelBooking(b.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    final rs =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('My bookings')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_BookingsView>(
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
            if (view.bookings.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('No bookings yet.')),
              ]);
            }
            return ListView.separated(
              itemCount: view.bookings.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final b = view.bookings[i];
                final eq = view.equipment[b.equipmentId];
                final open = b.status != 'cancelled' && b.status != 'completed';
                return ListTile(
                  title: Text(eq?.name ?? 'Equipment'),
                  subtitle: Text(
                    '${df.format(b.startDate)} → ${df.format(b.endDate)}'
                    ' • ${b.days} day${b.days == 1 ? '' : 's'}\n'
                    '${rs.format(b.totalAmount)} • ${b.status}',
                  ),
                  isThreeLine: true,
                  trailing: open
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Cancel',
                          onPressed: () => _cancel(b),
                        )
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BookingsView {
  _BookingsView(this.bookings, this.equipment);
  final List<EquipmentBooking> bookings;
  final Map<String, RentalEquipment> equipment;
}
