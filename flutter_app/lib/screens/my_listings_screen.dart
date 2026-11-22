import 'package:flutter/material.dart';

import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import 'listing_detail_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key, required this.service});
  final MarketplaceService service;

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late Future<List<MarketplaceListing>> _load = widget.service.myListings();

  Future<void> _refresh() async {
    setState(() => _load = widget.service.myListings());
    await _load;
  }

  Future<void> _open(MarketplaceListing l) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ListingDetailScreen(service: widget.service, listing: l),
      ),
    );
    if (changed == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My listings')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<MarketplaceListing>>(
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
                ),
              ]);
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('You have not listed anything yet.')),
              ]);
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final l = items[i];
                return ListTile(
                  title: Text(l.title),
                  subtitle: Text(
                    '${l.quantity} ${l.unit} • ${l.currency} ${l.price.toStringAsFixed(2)}'
                    '${l.isHidden ? '\nHidden by an admin' : ''}',
                  ),
                  isThreeLine: l.isHidden,
                  trailing:
                      Chip(label: Text(l.isActive ? 'Available' : l.status)),
                  onTap: () => _open(l),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
