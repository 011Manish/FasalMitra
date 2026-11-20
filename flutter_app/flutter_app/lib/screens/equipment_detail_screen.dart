import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/equipment_booking.dart';
import '../models/rental_equipment.dart';
import '../services/equipment_rental_service.dart';
import 'my_equipment_bookings_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  const EquipmentDetailScreen({super.key, required this.equipment});
  final RentalEquipment equipment;

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  late final _service = EquipmentRentalService(Supabase.instance.client);
  late Future<List<EquipmentBooking>> _busy;
  DateTimeRange? _range;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _busy = _service.bookingsForEquipment(widget.equipment.id);
  }

  bool _overlapsBusy(DateTimeRange r, List<EquipmentBooking> busy) {
    for (final b in busy) {
      if (!r.end.isBefore(b.startDate) && !r.start.isAfter(b.endDate)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _pickRange(List<EquipmentBooking> busy) async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 180)),
      initialDateRange: _range,
    );
    if (picked == null) return;
    if (_overlapsBusy(picked, busy)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Those dates overlap an existing booking.')),
      );
      return;
    }
    setState(() => _range = picked);
  }

  Future<void> _submit() async {
    if (_range == null) return;
    setState(() => _submitting = true);
    try {
      await _service.requestBooking(
        equipment: widget.equipment,
        startDate: _range!.start,
        endDate: _range!.end,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MyEquipmentBookingsScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not book: $e')));
      setState(() => _submitting = false);
    }
  }

  Future<void> _callProvider() async {
    final phone = widget.equipment.providerPhone;
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.equipment;
    final rs =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);
    final df = DateFormat.yMMMd();
    final days =
        _range == null ? 0 : _range!.end.difference(_range!.start).inDays + 1;
    final total = days * e.dailyRate;

    return Scaffold(
      appBar: AppBar(title: Text(e.name)),
      body: FutureBuilder<List<EquipmentBooking>>(
        future: _busy,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load: ${snap.error}'),
            );
          }
          final busy = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (e.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    e.photoUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.agriculture_outlined, size: 64),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(e.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('${e.category} • ${rs.format(e.dailyRate)}/day',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (e.description.isNotEmpty) Text(e.description),
              if (e.providerName != null) ...[
                const Divider(height: 32),
                Text('Provider',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(e.providerName!),
                if (e.providerAddress != null) Text(e.providerAddress!),
                if (e.providerPhone != null)
                  TextButton.icon(
                    icon: const Icon(Icons.phone),
                    label: Text(e.providerPhone!),
                    onPressed: _callProvider,
                  ),
              ],
              const Divider(height: 32),
              Text('Pick dates',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_range == null
                    ? 'Select date range'
                    : '${df.format(_range!.start)} → ${df.format(_range!.end)}'),
                onPressed: () => _pickRange(busy),
              ),
              if (busy.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Already booked:',
                    style: Theme.of(context).textTheme.bodySmall),
                for (final b in busy)
                  Text('  ${df.format(b.startDate)} → ${df.format(b.endDate)}',
                      style: Theme.of(context).textTheme.bodySmall),
              ],
              const Divider(height: 32),
              if (_range != null) ...[
                Text(
                    '$days day${days == 1 ? '' : 's'} × ${rs.format(e.dailyRate)}'),
                const SizedBox(height: 4),
                Text('Total: ${rs.format(total)}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Payment pending — arrange with the provider after your booking is confirmed.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _range == null || _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Request booking'),
              ),
            ],
          );
        },
      ),
    );
  }
}
