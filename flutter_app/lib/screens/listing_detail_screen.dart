import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.service, required this.listing});
  final MarketplaceService service;
  final MarketplaceListing listing;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late Future<List<MarketplaceBid>> _bids;
  final _bidAmount = TextEditingController();
  final _buyQuantity = TextEditingController(text: '1');
  bool _busy = false;

  bool get _isMine =>
      widget.listing.sellerId == Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _bids = widget.listing.isAuction
        ? widget.service.bidsFor(widget.listing.id)
        : Future.value(const []);
  }

  Future<void> _placeBid() async {
    final amount = double.tryParse(_bidAmount.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid bid amount')));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.service.placeBid(widget.listing.id, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid placed')));
        setState(() => _bids = widget.service.bidsFor(widget.listing.id));
        _bidAmount.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bid rejected: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestToBuy() async {
    final qty = double.tryParse(_buyQuantity.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.service.requestToBuy(widget.listing.id, qty);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Request sent to seller')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelListing() async {
    setState(() => _busy = true);
    try {
      await widget.service.cancel(widget.listing.id);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markSold() async {
    setState(() => _busy = true);
    try {
      await widget.service.markSold(widget.listing.id);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final df = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.title),
        actions: [
          if (_isMine && l.status == 'active')
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'cancel') _cancelListing();
                if (v == 'sold') _markSold();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'cancel', child: Text('Cancel listing')),
                if (!l.isAuction) const PopupMenuItem(value: 'sold', child: Text('Mark as sold')),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Chip(label: Text(listingCategoryLabels[l.itemCategory] ?? l.itemCategory)),
          const SizedBox(height: 12),
          if (l.description != null) ...[
            Text(l.description!),
            const SizedBox(height: 16),
          ],
          Text('${l.quantity} ${l.unit} available',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            l.isAuction
                ? 'Current bid: ${l.currency} ${l.currentPrice.toStringAsFixed(2)}'
                : 'Price: ${l.currency} ${l.price.toStringAsFixed(2)} / ${l.unit}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (l.isAuction && l.auctionEndAt != null) ...[
            const SizedBox(height: 4),
            Text(
              l.auctionHasEnded ? 'Auction ended ${df.format(l.auctionEndAt!)}'
                                 : 'Auction ends ${df.format(l.auctionEndAt!)}',
              style: TextStyle(color: l.auctionHasEnded ? Colors.red : null),
            ),
          ],
          const SizedBox(height: 24),

          if (!_isMine && l.status == 'active' && l.isAuction && !l.auctionHasEnded) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bidAmount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Your bid (NPR)'),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(onPressed: _busy ? null : _placeBid, child: const Text('Place bid')),
              ],
            ),
            const SizedBox(height: 16),
            Text('Bid history', style: Theme.of(context).textTheme.titleMedium),
            FutureBuilder<List<MarketplaceBid>>(
              future: _bids,
              builder: (context, snap) {
                final bids = snap.data ?? [];
                if (bids.isEmpty) return const Text('No bids yet.');
                return Column(
                  children: bids
                      .map((b) => ListTile(
                            dense: true,
                            title: Text('${l.currency} ${b.amount.toStringAsFixed(2)}'),
                            subtitle: Text(df.format(b.createdAt)),
                          ))
                      .toList(),
                );
              },
            ),
          ],

          if (!_isMine && l.status == 'active' && !l.isAuction) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buyQuantity,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Quantity (${l.unit})'),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                    onPressed: _busy ? null : _requestToBuy, child: const Text('Request to buy')),
              ],
            ),
          ],

          if (l.status != 'active') ...[
            const SizedBox(height: 8),
            Chip(label: Text('Listing ${l.status}')),
          ],
        ],
      ),
    );
  }
}
