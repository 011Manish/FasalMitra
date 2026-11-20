import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/equipment_booking.dart';
import '../models/rental_equipment.dart';

class EquipmentRentalService {
  EquipmentRentalService(this._sb);
  final SupabaseClient _sb;

  String get _uid => _sb.auth.currentUser!.id;

  Future<List<RentalEquipment>> listEquipment({String? category}) async {
    var q = _sb.from('rental_equipment').select();
    if (category != null) q = q.eq('category', category);
    final rows = await q.order('name', ascending: true);
    return (rows as List)
        .map((r) => RentalEquipment.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<EquipmentBooking>> listMyBookings() async {
    final rows = await _sb
        .from('equipment_bookings')
        .select()
        .order('requested_at', ascending: false);
    return (rows as List)
        .map((r) => EquipmentBooking.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<EquipmentBooking>> bookingsForEquipment(
      String equipmentId) async {
    final rows = await _sb.rpc(
      'equipment_booking_availability',
      params: {'p_equipment_id': equipmentId},
    );
    return (rows as List)
        .map((r) => EquipmentBooking(
              id: '',
              equipmentId: equipmentId,
              startDate: DateTime.parse(r['start_date'] as String),
              endDate: DateTime.parse(r['end_date'] as String),
              status: r['status'] as String,
              totalAmount: 0,
              requestedAt: DateTime.now(),
            ))
        .toList();
  }

  Future<EquipmentBooking> requestBooking({
    required RentalEquipment equipment,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final days = endDate.difference(startDate).inDays + 1;
    final total = equipment.dailyRate * days;
    final row = await _sb
        .from('equipment_bookings')
        .insert({
          'user_id': _uid,
          'equipment_id': equipment.id,
          'start_date': _dateOnly(startDate),
          'end_date': _dateOnly(endDate),
          'status': 'pending',
          'total_amount': total,
          'place_id': equipment.placeId,
          'place_name': equipment.providerName,
          'place_address': equipment.providerAddress,
        })
        .select()
        .single();
    return EquipmentBooking.fromMap(row);
  }

  Future<void> cancelBooking(String bookingId) async {
    await _sb
        .from('equipment_bookings')
        .update({'status': 'cancelled'}).eq('id', bookingId);
  }

  String _dateOnly(DateTime d) => d.toIso8601String().substring(0, 10);
}
