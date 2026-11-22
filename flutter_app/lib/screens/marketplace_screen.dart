import 'package:flutter/material.dart';

import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import 'create_listing_screen.dart';
import 'listing_detail_screen.dart';
import 'my_listings_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key, required this.service});
  final MarketplaceService service;

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  late Future<List<MarketplaceListing>> _load = widget.service.browse();

  String? _role;

  bool get _canSell => _role == 'farmer' || _role == 'admin';

  @override
  void initState() {
    super.initState();
    widget.service.myRole().then((r) {
      if (mounted) setState(() => _role = r);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _load = widget.service.browse(search: _search));
    await _load;
  }

  void _runSearch(String value) {
    _search = value.trim();
    setState(() => _load = widget.service.browse(search: _search));
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => CreateListingScreen(service: widget.service)),
    );
    if (created == true) _refresh();
  }

  Future<void> _openDetail(MarketplaceListing listing) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ListingDetailScreen(service: widget.service, listing: listing),
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
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'My listings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => MyListingsScreen(service: widget.service)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: _runSearch,
              decoration: InputDecoration(
                hintText: 'Search crop or district',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _runSearch('');
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
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
                    return ListView(children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(
                          _search.isEmpty
                              ? _canSell
                                  ? 'No listings yet.\nTap + to sell something.'
                                  : 'No listings yet.'
                              : 'No listings match "$_search".',
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
                        leading: const CircleAvatar(child: Icon(Icons.grass)),
                        title: Text(l.title),
                        subtitle: Text(
                          [
                            '${l.quantity} ${l.unit}',
                            if (l.locationText.isNotEmpty) l.locationText,
                          ].join(' • '),
                        ),
                        trailing: Text(
                          '${l.currency} ${l.price.toStringAsFixed(2)}\n/ ${l.unit}',
                          textAlign: TextAlign.right,
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
      floatingActionButton: _canSell
          ? FloatingActionButton(
              onPressed: _openCreate,
              tooltip: 'Sell produce',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
