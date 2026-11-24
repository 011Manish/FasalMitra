import 'package:flutter/material.dart';

import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import 'create_listing_screen.dart';
import 'listing_detail_screen.dart';
import 'listing_enquiries_section.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key, required this.service});
  final MarketplaceService service;

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late Future<List<MarketplaceListing>> _load = widget.service.myListings();
  bool _busy = false;

  void _snack(String message, {VoidCallback? onRetry}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      action: onRetry == null
          ? null
          : SnackBarAction(label: 'Retry', onPressed: onRetry),
    ));
  }

  Future<void> _refresh() async {
    setState(() => _load = widget.service.myListings());
    // The list itself shows a failure; this only ends the refresh spinner.
    await _load.then<void>((_) {}, onError: (_) {});
  }

  Future<void> _setStatus(
      MarketplaceListing listing, String status, String done) async {
    setState(() => _busy = true);
    try {
      await widget.service.setStatus(listing.id, status);
      if (!mounted) return;
      _snack(done);
      await _refresh();
    } catch (e) {
      _snack(
        marketplaceErrorMessage(e, fallback: 'Could not update the listing.'),
        onRetry: () => _setStatus(listing, status, done),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(MarketplaceListing listing) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CreateListingScreen(service: widget.service, existing: listing),
      ),
    );
    if (saved == true && mounted) await _refresh();
  }

  void _view(MarketplaceListing listing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ListingDetailScreen(service: widget.service, listing: listing),
      ),
    );
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
                RetryMessage(
                  message: marketplaceErrorMessage(snap.error!,
                      fallback: 'Could not load your listings.'),
                  onRetry: _refresh,
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
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => _listingCard(items[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _listingCard(MarketplaceListing l) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ExpansionTile(
        key: ValueKey(l.id),
        title: Text(l.title),
        subtitle: Text(
          '${l.quantityLabel} • ${l.currency} ${l.price.toStringAsFixed(2)}\n'
          '${l.statusLabel}${l.isHidden ? ' • Hidden by an admin' : ''}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _edit(l),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              TextButton(
                onPressed: () => _view(l),
                child: const Text('View listing'),
              ),
              if (l.isActive)
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _setStatus(
                          l, ListingStatus.sold, 'Listing marked as sold.'),
                  child: const Text('Mark as sold'),
                ),
              if (l.status == ListingStatus.sold ||
                  l.status == ListingStatus.cancelled)
                FilledButton.tonal(
                  onPressed: _busy
                      ? null
                      : () => _setStatus(l, ListingStatus.active,
                          'Listing is available again.'),
                  child: const Text('Mark available again'),
                ),
              if (l.isActive)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _setStatus(
                          l, ListingStatus.cancelled, 'Listing removed.'),
                  child: const Text('Remove listing'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ListingEnquiriesSection(service: widget.service, listingId: l.id),
        ],
      ),
    );
  }
}
