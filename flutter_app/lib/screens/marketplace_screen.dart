import 'package:flutter/material.dart';

import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import 'create_listing_screen.dart';
import 'listing_detail_screen.dart';
import 'listing_enquiries_section.dart';
import 'my_listings_screen.dart';
import '../l10n/app_lang.dart';
import '../widgets/design_kit.dart';
import '../widgets/figma_icons.dart';

typedef _BrowseResult = ({
  List<MarketplaceListing> listings,
  Map<String, String> thumbs,
});

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key, required this.service});
  final MarketplaceService service;

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  String _search = '';
  String _district = '';
  late Future<_BrowseResult> _load = _fetch();

  String? _role;

  bool get _canSell => _role == 'farmer' || _role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    try {
      final role = await widget.service.myRole();
      if (mounted) setState(() => _role = role);
    } catch (_) {
      // The server enforces the role; without it the + button skips the pre-check.
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<_BrowseResult> _fetch() async {
    final listings =
        await widget.service.browse(search: _search, district: _district);
    final thumbs =
        await widget.service.thumbnailUrls([for (final l in listings) l.id]);
    return (listings: listings, thumbs: thumbs);
  }

  void _apply() {
    _search = _searchCtrl.text.trim();
    _district = _districtCtrl.text.trim();
    setState(() => _load = _fetch());
  }

  Future<void> _refresh() async {
    setState(() => _load = _fetch());
    // The list itself shows a failure; this only ends the refresh spinner.
    await _load.then<void>((_) {}, onError: (_) {});
  }

  Future<void> _openCreate() async {
    if (_role != null && !_canSell) {
      _snack(farmerOnlyMessage);
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => CreateListingScreen(service: widget.service)),
    );
    if (created == true && mounted) await _refresh();
  }

  void _openDetail(MarketplaceListing listing) {
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
      appBar: AppBar(
        title: Text(tr('Market'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          const LangToggle(),
          IconButton(
            icon: const FIcon(Icons.inventory_2_outlined),
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
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _FilterField(
                    controller: _searchCtrl,
                    hint: 'Search crop',
                    icon: Icons.search,
                    onApply: _apply,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _FilterField(
                    controller: _districtCtrl,
                    hint: 'District',
                    icon: Icons.place_outlined,
                    onApply: _apply,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<_BrowseResult>(
                future: _load,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return ListView(children: [
                      RetryMessage(
                        message: marketplaceErrorMessage(snap.error!,
                            fallback: 'Could not load listings.'),
                        onRetry: _refresh,
                      ),
                    ]);
                  }
                  final result = snap.data!;
                  if (result.listings.isEmpty) {
                    return ListView(children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(
                          _search.isNotEmpty || _district.isNotEmpty
                              ? 'No listings match your search.'
                              : _canSell
                                  ? 'No listings yet.\nTap + to sell something.'
                                  : 'No listings yet.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ]);
                  }
                  final priceStyle = Theme.of(context).textTheme.titleSmall;
                  return ListView.separated(
                    itemCount: result.listings.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final l = result.listings[i];
                      return ListTile(
                        leading: _Thumb(url: result.thumbs[l.id]),
                        title: Text(l.title),
                        subtitle: Text(
                          [
                            l.quantityLabel,
                            if (l.locationText.isNotEmpty) l.locationText,
                          ].join(' • '),
                        ),
                        trailing: Text(
                          '${l.currency} ${l.price.toStringAsFixed(2)}\n/ ${l.unit}',
                          textAlign: TextAlign.right,
                          style: priceStyle,
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
        tooltip: 'Sell produce',
        child: const FIcon(Icons.add),
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onApply,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onApply(),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: FIcon(icon),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  icon: const FIcon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onApply();
                  },
                ),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});
  final String? url;

  static const _size = 56.0;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const FIcon(Icons.grass),
    );
    final u = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: u == null
          ? fallback
          : Image.network(
              u,
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}
