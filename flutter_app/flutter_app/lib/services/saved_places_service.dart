import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agri_place.dart';

class SavedPlacesService {
  final SupabaseClient _client;
  SavedPlacesService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<AgriPlace>> fetchSavedPlaces() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('saved_agri_places')
        .select()
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    return (rows as List<dynamic>).map((r) {
      final map = r as Map<String, dynamic>;
      return AgriPlace(
        placeId: map['place_id'] as String,
        name: map['name'] as String,
        address: map['address'] as String?,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        rating: (map['rating'] as num?)?.toDouble(),
        distanceKm: (map['distance_km'] as num?)?.toDouble(),
        placeType: AgriPlaceType.values.firstWhere(
          (t) => t.name == map['place_type'],
          orElse: () => AgriPlaceType.agriShop,
        ),
      );
    }).toList();
  }

  Future<void> savePlace(AgriPlace place) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('saved_agri_places').upsert({
      'user_id': userId,
      'place_id': place.placeId,
      'name': place.name,
      'address': place.address,
      'latitude': place.latitude,
      'longitude': place.longitude,
      'place_type': place.placeType.name,
      'rating': place.rating,
      'distance_km': place.distanceKm,
    });
  }

  Future<void> unsavePlace(String placeId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('saved_agri_places')
        .delete()
        .eq('user_id', userId)
        .eq('place_id', placeId);
  }

  Future<bool> isSaved(String placeId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final rows = await _client
        .from('saved_agri_places')
        .select('id')
        .eq('user_id', userId)
        .eq('place_id', placeId)
        .limit(1);

    return (rows as List).isNotEmpty;
  }
}
