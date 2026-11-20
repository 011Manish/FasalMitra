import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/agri_place.dart';
import '../services/nearby_places_service.dart';
import 'place_detail_sheet.dart';

class NearbyAgricultureScreen extends StatefulWidget {
  const NearbyAgricultureScreen({super.key});

  @override
  State<NearbyAgricultureScreen> createState() =>
      _NearbyAgricultureScreenState();
}

class _NearbyAgricultureScreenState extends State<NearbyAgricultureScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  late final TabController _tabController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  Position? _currentPosition;
  bool _locationLoading = true;
  String? _locationError;

  AgriPlaceType _selectedType = AgriPlaceType.all;
  bool _placesLoading = false;
  String? _placesError;
  List<AgriPlace> _places = [];
  Map<AgriPlaceType, List<AgriPlace>> _allPlaces = {};

  Set<Marker> _markers = {};
  AgriPlace? _selectedPlace;

  int _radiusKm = 10;

  final _service = NearbyPlacesService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _determinePosition();
    if (_currentPosition != null) {
      await _fetchPlaces();
    }
  }

  Future<void> _determinePosition() async {
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled. Please enable GPS.';
          _locationLoading = false;
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied.';
            _locationLoading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permission permanently denied. Enable it in Settings.';
          _locationLoading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = pos;
        _locationLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Could not get location: $e';
        _locationLoading = false;
      });
    }
  }

  Future<void> _fetchPlaces() async {
    if (_currentPosition == null) return;
    setState(() {
      _placesLoading = true;
      _placesError = null;
      _selectedPlace = null;
    });
    try {
      final allMap = await _service.fetchAllTypes(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusMeters: _radiusKm * 1000,
      );
      if (!mounted) return;
      setState(() {
        _allPlaces = allMap;
        _placesLoading = false;
      });
      _applyFilter(_selectedType);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _placesLoading = false;
        _placesError = 'Failed to load places: $e';
      });
    }
  }

  void _applyFilter(AgriPlaceType type) {
    setState(() {
      _selectedType = type;
      if (type == AgriPlaceType.all) {
        final all = _allPlaces.values.expand((l) => l).toList();
        final seen = <String>{};
        _places = all.where((p) => seen.add(p.placeId)).toList()
          ..sort(
              (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
      } else {
        _places = List.from(_allPlaces[type] ?? []);
      }
      _updateMarkers();
    });
  }

  void _updateMarkers() {
    final pos = _currentPosition;
    final markers = <Marker>{};

    if (pos != null) {
      markers.add(Marker(
        markerId: const MarkerId('_me'),
        position: LatLng(pos.latitude, pos.longitude),
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    for (final place in _places) {
      final hue = _hueForType(place.placeType);
      markers.add(Marker(
        markerId: MarkerId(place.placeId),
        position: LatLng(place.latitude, place.longitude),
        infoWindow: InfoWindow(title: place.name, snippet: place.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        onTap: () => _onMarkerTap(place),
      ));
    }
    setState(() => _markers = markers);
  }

  double _hueForType(AgriPlaceType type) {
    switch (type) {
      case AgriPlaceType.agriShop:
        return BitmapDescriptor.hueGreen;
      case AgriPlaceType.coldStorage:
        return BitmapDescriptor.hueCyan;
      case AgriPlaceType.equipmentRental:
        return BitmapDescriptor.hueOrange;
      case AgriPlaceType.collectionCenter:
        return BitmapDescriptor.hueViolet;
      case AgriPlaceType.veterinaryClinic:
        return BitmapDescriptor.hueRed;
      case AgriPlaceType.fertilizerDealer:
        return BitmapDescriptor.hueYellow;
      case AgriPlaceType.seedStore:
        return BitmapDescriptor.hueMagenta;
      default:
        return BitmapDescriptor.hueGreen;
    }
  }

  void _onMarkerTap(AgriPlace place) {
    setState(() => _selectedPlace = place);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(place.latitude, place.longitude), 15),
    );
    _showPlaceSheet(place);
  }

  void _onPlaceCardTap(AgriPlace place) {
    setState(() => _selectedPlace = place);
    _tabController.animateTo(0);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(place.latitude, place.longitude), 15),
    );
    _showPlaceSheet(place);
  }

  void _showPlaceSheet(AgriPlace place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceDetailSheet(
        place: place,
        onGetDirections: () => _openDirections(place),
        onCall: place.phoneNumber != null
            ? () => _callPlace(place.phoneNumber!)
            : null,
      ),
    );
  }

  Future<void> _openDirections(AgriPlace place) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${place.latitude},${place.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _callPlace(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _showRadiusDialog() async {
    int tempRadius = _radiusKm;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Search Radius'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$tempRadius km',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: tempRadius.toDouble(),
                min: 2,
                max: 50,
                divisions: 48,
                label: '$tempRadius km',
                activeColor: const Color(0xFF2E7D32),
                onChanged: (v) => setDialogState(() => tempRadius = v.round()),
              ),
              const Text(
                'Larger radius = more results but slower',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32)),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _radiusKm = tempRadius);
                _fetchPlaces();
              },
              child:
                  const Text('Search', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: _locationLoading
          ? const _LoadingView(message: 'Getting your location…')
          : _locationError != null
              ? _ErrorView(message: _locationError!, onRetry: _init)
              : Column(
                  children: [
                    _buildFilterChips(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [_buildMapTab(), _buildListTab()],
                      ),
                    ),
                  ],
                ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nearby Agriculture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Network',
              style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: 'Search Radius',
          onPressed: _showRadiusDialog,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _placesLoading ? null : _fetchPlaces,
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final types = [
      AgriPlaceType.all,
      ...AgriPlaceType.values.where((t) => t != AgriPlaceType.all)
    ];
    return Container(
      color: Colors.white,
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = types[i];
          final selected = _selectedType == t;
          return FilterChip(
            label: Text(
              '${t.icon} ${t.label}',
              style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : Colors.black87),
            ),
            selected: selected,
            onSelected: (_) => _applyFilter(t),
            backgroundColor: Colors.grey[100],
            selectedColor: const Color(0xFF2E7D32),
            checkmarkColor: Colors.white,
            side: BorderSide(
                color: selected ? const Color(0xFF2E7D32) : Colors.grey[300]!),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF2E7D32),
        labelColor: const Color(0xFF2E7D32),
        unselectedLabelColor: Colors.grey,
        tabs: [
          Tab(
              icon: const Icon(Icons.map_outlined, size: 18),
              text: 'Map (${_places.length})'),
          const Tab(
              icon: Icon(Icons.list_alt_outlined, size: 18), text: 'List'),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    final pos = _currentPosition!;
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (c) => _mapController = c,
          initialCameraPosition: CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 13,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
        ),
        if (_placesLoading)
          const Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(child: _LoadingChip()),
          ),
        if (_placesError != null)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _InlineError(message: _placesError!, onRetry: _fetchPlaces),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: _MapLegend(selectedType: _selectedType),
        ),
      ],
    );
  }

  Widget _buildListTab() {
    if (_placesLoading) {
      return const _LoadingView(message: 'Finding places near you…');
    }
    if (_placesError != null) {
      return _ErrorView(message: _placesError!, onRetry: _fetchPlaces);
    }
    if (_places.isEmpty) {
      return _EmptyView(
          type: _selectedType,
          radiusKm: _radiusKm,
          onChangeRadius: _showRadiusDialog);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _places.length,
      itemBuilder: (_, i) => _PlaceListTile(
        place: _places[i],
        isSelected: _selectedPlace?.placeId == _places[i].placeId,
        onTap: () => _onPlaceCardTap(_places[i]),
      ),
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF2E7D32)),
        ),
        SizedBox(width: 8),
        Text('Searching…', style: TextStyle(fontSize: 13)),
      ]),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final String message;
  const _LoadingView({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: Color(0xFF2E7D32)),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_off, size: 56, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32)),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Retry', style: TextStyle(color: Colors.white)),
            onPressed: onRetry,
          ),
        ]),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InlineError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 12, color: Colors.red))),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
          ),
        ]),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final AgriPlaceType type;
  final int radiusKm;
  final VoidCallback onChangeRadius;
  const _EmptyView(
      {required this.type,
      required this.radiusKm,
      required this.onChangeRadius});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(type.icon, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(
          'No ${type.label} found within $radiusKm km',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const Text('Try increasing the search radius',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.tune, color: Color(0xFF2E7D32)),
          label: const Text('Change Radius',
              style: TextStyle(color: Color(0xFF2E7D32))),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF2E7D32))),
          onPressed: onChangeRadius,
        ),
      ]),
    );
  }
}

class _PlaceListTile extends StatelessWidget {
  final AgriPlace place;
  final bool isSelected;
  final VoidCallback onTap;
  const _PlaceListTile(
      {required this.place, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isSelected
            ? const BorderSide(color: Color(0xFF2E7D32), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                  child: Text(place.placeType.icon,
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (place.address != null)
                      Text(
                        place.address!,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (place.rating != null) ...[
                        const Icon(Icons.star, size: 13, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(place.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500)),
                        if (place.userRatingsTotal != null)
                          Text(' (${place.userRatingsTotal})',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 8),
                      ],
                      if (place.isOpen != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: place.isOpen!
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            place.isOpen! ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: 10,
                              color: place.isOpen!
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ]),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (place.distanceKm != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    place.distanceKm! < 1
                        ? '${(place.distanceKm! * 1000).round()}m'
                        : '${place.distanceKm!.toStringAsFixed(1)}km',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 6),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final AgriPlaceType selectedType;
  const _MapLegend({required this.selectedType});

  @override
  Widget build(BuildContext context) {
    final types = selectedType == AgriPlaceType.all
        ? AgriPlaceType.values.where((t) => t != AgriPlaceType.all).toList()
        : [selectedType];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: types
            .map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(t.icon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(t.label, style: const TextStyle(fontSize: 10)),
                  ]),
                ))
            .toList(),
      ),
    );
  }
}
