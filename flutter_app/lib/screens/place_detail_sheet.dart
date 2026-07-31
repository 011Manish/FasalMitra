import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/agri_place.dart';

class PlaceDetailSheet extends StatelessWidget {
  final AgriPlace place;
  final VoidCallback onGetDirections;
  final VoidCallback? onCall;

  const PlaceDetailSheet({
    super.key,
    required this.place,
    required this.onGetDirections,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const _DragHandle(),
            _SheetHeader(place: place),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  _StatusRow(place: place),
                  const SizedBox(height: 12),
                  if (place.address != null) ...[
                    _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: place.address!),
                    const SizedBox(height: 8),
                  ],
                  if (place.distanceKm != null)
                    _InfoRow(
                      icon: Icons.directions_walk_outlined,
                      label: place.distanceKm! < 1
                          ? '${(place.distanceKm! * 1000).round()} meters away'
                          : '${place.distanceKm!.toStringAsFixed(2)} km away',
                    ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.directions_outlined,
                        label: 'Directions',
                        color: const Color(0xFF2E7D32),
                        onTap: () {
                          Navigator.pop(context);
                          onGetDirections();
                        },
                      ),
                    ),
                    if (onCall != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.phone_outlined,
                          label: 'Call',
                          color: Colors.blue[700]!,
                          onTap: () {
                            Navigator.pop(context);
                            onCall!();
                          },
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        color: Colors.grey[700]!,
                        onTap: () => _sharePlaceLocation(context),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new,
                        size: 16, color: Color(0xFF2E7D32)),
                    label: const Text('Open in Google Maps',
                        style: TextStyle(color: Color(0xFF2E7D32))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _openInGoogleMaps(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${place.latitude},${place.longitude}'
      '&query_place_id=${place.placeId}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _sharePlaceLocation(BuildContext context) {
    final text =
        '${place.name}\n${place.address ?? ''}\nhttps://maps.google.com/?q=${place.latitude},${place.longitude}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Share: $text'), duration: const Duration(seconds: 2)),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final AgriPlace place;
  const _SheetHeader({required this.place});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(place.placeType.icon,
                    style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    place.placeType.label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (place.rating != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    ...List.generate(5, (i) {
                      final filled = i < place.rating!.floor();
                      final half = !filled &&
                          i < place.rating! &&
                          place.rating! - i >= 0.5;
                      return Icon(
                        filled
                            ? Icons.star
                            : half
                                ? Icons.star_half
                                : Icons.star_border,
                        size: 14,
                        color: Colors.amber,
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      '${place.rating!.toStringAsFixed(1)}'
                      '${place.userRatingsTotal != null ? ' (${place.userRatingsTotal} reviews)' : ''}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final AgriPlace place;
  const _StatusRow({required this.place});

  @override
  Widget build(BuildContext context) {
    if (place.isOpen == null) return const SizedBox.shrink();
    return Row(children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
            color: place.isOpen! ? Colors.green : Colors.red,
            shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        place.isOpen! ? 'Open now' : 'Closed',
        style: TextStyle(
          fontSize: 13,
          color: place.isOpen! ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black87))),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
