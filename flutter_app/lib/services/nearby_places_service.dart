import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agri_place.dart';

class NearbyPlacesService {
  final _client = Supabase.instance.client;

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  Future<List<AgriPlace>> _nearbySearch({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required String keyword,
    required AgriPlaceType placeType,
  }) async {
    final res = await _client.functions.invoke('nearby-places', body: {
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'keyword': keyword,
    });

    final results = (res.data['results'] as List<dynamic>? ?? []);
    return results.map((r) {
      final place =
          AgriPlace.fromGooglePlacesJson(r as Map<String, dynamic>, placeType);
      final dist =
          _distanceKm(latitude, longitude, place.latitude, place.longitude);
      return place.copyWith(distanceKm: dist);
    }).toList();
  }

  Future<List<AgriPlace>> fetchPlacesForType({
    required double latitude,
    required double longitude,
    required AgriPlaceType placeType,
    int radiusMeters = 10000,
  }) async {
    try {
      final keywords = placeType == AgriPlaceType.all
          ? AgriPlaceType.values
              .where((t) => t != AgriPlaceType.all)
              .expand((t) => t.searchKeywords)
              .toList()
          : placeType.searchKeywords;

      final futures = keywords.map((kw) => _nearbySearch(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            keyword: kw,
            placeType: placeType,
          ));

      final results = await Future.wait(futures);
      final combined = results.expand((list) => list).toList();

      final seen = <String>{};
      final unique = combined.where((p) => seen.add(p.placeId)).toList()
        ..sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));

      return unique;
    } catch (_) {
      return _mockPlaces(latitude, longitude, placeType);
    }
  }

  Future<Map<AgriPlaceType, List<AgriPlace>>> fetchAllTypes({
    required double latitude,
    required double longitude,
    int radiusMeters = 10000,
  }) async {
    final types =
        AgriPlaceType.values.where((t) => t != AgriPlaceType.all).toList();

    final futures = types.map((t) => fetchPlacesForType(
          latitude: latitude,
          longitude: longitude,
          placeType: t,
          radiusMeters: radiusMeters,
        ));

    final results = await Future.wait(futures);
    return {for (var i = 0; i < types.length; i++) types[i]: results[i]};
  }

  List<AgriPlace> _mockPlaces(double lat, double lon, AgriPlaceType type) {
    const mockData = [
      {
        'name': 'Shree Krishna Krishi Pasal',
        'address': 'Butwal, Rupandehi',
        'latOff': 0.005,
        'lonOff': 0.003,
        'rating': 4.2,
        'type': AgriPlaceType.agriShop
      },
      {
        'name': 'Himalayan Cold Storage',
        'address': 'Bhairahawa, Rupandehi',
        'latOff': 0.012,
        'lonOff': -0.008,
        'rating': 3.8,
        'type': AgriPlaceType.coldStorage
      },
      {
        'name': 'Nepal Tractor Rental Services',
        'address': 'Tilottama, Rupandehi',
        'latOff': -0.007,
        'lonOff': 0.015,
        'rating': 4.5,
        'type': AgriPlaceType.equipmentRental
      },
      {
        'name': 'Sabji Collection Center Butwal',
        'address': 'Butwal-10, Rupandehi',
        'latOff': 0.003,
        'lonOff': -0.005,
        'rating': 4.0,
        'type': AgriPlaceType.collectionCenter
      },
      {
        'name': 'Pashu Chikitsa Kendra',
        'address': 'Butwal-5, Rupandehi',
        'latOff': -0.009,
        'lonOff': -0.011,
        'rating': 4.3,
        'type': AgriPlaceType.veterinaryClinic
      },
      {
        'name': 'Siddhartha Fertilizer Store',
        'address': 'Butwal, Rupandehi',
        'latOff': 0.008,
        'lonOff': 0.006,
        'rating': 3.9,
        'type': AgriPlaceType.fertilizerDealer
      },
      {
        'name': 'Biu Bijan Seed Center',
        'address': 'Rupandehi',
        'latOff': -0.004,
        'lonOff': 0.009,
        'rating': 4.1,
        'type': AgriPlaceType.seedStore
      },
    ];

    final filtered = type == AgriPlaceType.all
        ? mockData
        : mockData.where((d) => d['type'] == type).toList();

    return filtered.asMap().entries.map((entry) {
      final d = entry.value;
      final pLat = lat + (d['latOff'] as double);
      final pLon = lon + (d['lonOff'] as double);
      return AgriPlace(
        placeId: 'mock_${entry.key}_${type.name}',
        name: d['name'] as String,
        address: d['address'] as String,
        latitude: pLat,
        longitude: pLon,
        rating: d['rating'] as double,
        userRatingsTotal: 42 + entry.key * 11,
        isOpen: true,
        placeType: d['type'] as AgriPlaceType,
        distanceKm: _distanceKm(lat, lon, pLat, pLon),
      );
    }).toList()
      ..sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
  }
}
