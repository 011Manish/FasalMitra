import 'package:flutter/material.dart';

import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import 'create_listing_screen.dart';
import 'listing_detail_screen.dart';
import 'my_orders_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key, required this.service});
  final MarketplaceService service;

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String? _category;
  late Future<List<MarketplaceListing>> _load;

  @override
  void initState() {
    super.initState();
    _load = widget.service.browse();
  }

  Future<void> _refresh() async {
    setState(() => _load = widget.service.browse(category: _category));
    await _load;
  }

  void _setCategory(String? category) {
    setState(() {
      _category = category;
      _load = widget.service.browse(category: category);
    });
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateListingScreen(service: widget.service)),
    );
    if (created == true) _refresh();
  }

  Future<void> _openDetail(MarketplaceListing listing) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(service: widget.service, listing: listing),
      ),
    );
    if (changed == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'My orders',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MyOrdersScreen(service: widget.service)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _category == null,
                    onSelected: (_) => _setCategory(null),
                  ),
                ),
                ...listingCategories.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(listingCategoryLabels[c] ?? c),
                      selected: _category == c,
                      onSelected: (_) => _setCategory(c),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
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
                        child: Text('Could not load listings: ${snap.error}'),
                      ),
                    ]);
                  }
                  final listings = snap.data ?? [];
                  if (listings.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'No listings yet.\nTap + to sell something.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ]);
                  }
                  return ListView.separated(
                    itemCount: listings.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final l = listings[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(l.isAuction ? Icons.gavel : Icons.sell_outlined),
                        ),
                        title: Text(l.title),
                        subtitle: Text(
                          '${listingCategoryLabels[l.itemCategory] ?? l.itemCategory} — '
                          '${l.quantity} ${l.unit}'
                          '${l.isAuction ? ' — auction' : ''}',
                        ),
                        trailing: Text(
                          '${l.currency} ${l.currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _openDetail(l),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
    );
  }
}
