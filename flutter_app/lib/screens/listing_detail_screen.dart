import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen(
      {super.key, required this.service, required this.listing});
  final MarketplaceService service;
  final MarketplaceListing listing;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _message = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;

  late final Future<List<String>> _photoUrls = _loadPhotoUrls();
  late Future<List<ListingEnquiry>> _enquiries =
      widget.service.enquiriesFor(widget.listing.id);

  bool get _isMine =>
      widget.listing.sellerId == Supabase.instance.client.auth.currentUser?.id;

  @override
  void dispose() {
    _message.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<List<String>> _loadPhotoUrls() async {
    final photos = await widget.service.photos(widget.listing.id);
    return Future.wait(
        photos.map((p) => widget.service.signedUrl(p.storagePath)));
  }

  Future<void> _sendEnquiry() async {
    final msg = _message.text.trim();
    if (msg.isEmpty) {
      _snack('Write a short message to the seller.');
      return;
    }
    setState(() => _busy = true);
    try {
      final phone = _phone.text.trim();
      await widget.service.sendEnquiry(
        listingId: widget.listing.id,
        message: msg,
        phone: phone.isEmpty ? null : phone,
      );
      _message.clear();
      _snack('Enquiry sent to the seller.');
    } catch (e) {
      _snack('Could not send enquiry: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(String status) async {
    setState(() => _busy = true);
    try {
      await widget.service.setStatus(widget.listing.id, status);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Could not update listing: $e');
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final theme = Theme.of(context);
    final df = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(l.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<List<String>>(
            future: _photoUrls,
            builder: (context, snap) {
              final urls = snap.data ?? const <String>[];
              if (urls.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: urls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(urls[i],
                          height: 200, fit: BoxFit.cover),
                    ),
                  ),
                ),
              );
            },
          ),
          Text('${l.currency} ${l.price.toStringAsFixed(2)} / ${l.unit}',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('${l.quantity} ${l.unit} available',
              style: theme.textTheme.bodyLarge),
          if (l.locationText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.place_outlined, size: 18),
              const SizedBox(width: 4),
              Expanded(child: Text(l.locationText)),
            ]),
          ],
          if (l.availableFrom != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.event_outlined, size: 18),
              const SizedBox(width: 4),
              Text('Available from ${df.format(l.availableFrom!)}'),
            ]),
          ],
          if (l.description != null) ...[
            const SizedBox(height: 12),
            Text(l.description!),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            Chip(label: Text(l.isActive ? 'Available' : l.status)),
            if (l.isHidden && _isMine)
              const Chip(label: Text('Hidden by an admin')),
          ]),
          const SizedBox(height: 16),

          // Buyer: enquiry form
          if (!_isMine && l.isActive) ...[
            Text('Contact the seller', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _message,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Your message',
                hintText: 'Ask about price, quantity or pickup',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Your phone number (optional)'),
            ),
            const SizedBox(height: 12),
            Text(
              'Your name and the phone number saved in your profile are shared '
              'with the seller so they can reply.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _sendEnquiry,
              child: const Text('Send enquiry'),
            ),
          ],

          // Seller: status buttons and enquiries
          if (_isMine) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (l.isActive)
                FilledButton(
                  onPressed: _busy ? null : () => _setStatus('sold'),
                  child: const Text('Mark as sold'),
                ),
              if (l.status == 'sold')
                OutlinedButton(
                  onPressed: _busy ? null : () => _setStatus('active'),
                  child: const Text('Mark available again'),
                ),
              if (l.isActive)
                OutlinedButton(
                  onPressed: _busy ? null : () => _setStatus('cancelled'),
                  child: const Text('Remove listing'),
                ),
            ]),
            const SizedBox(height: 24),
            Text('Enquiries', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<List<ListingEnquiry>>(
              future: _enquiries,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Text('Could not load enquiries: ${snap.error}');
                }
                final items = snap.data ?? const <ListingEnquiry>[];
                if (items.isEmpty) return const Text('No enquiries yet.');
                final stamp = DateFormat.yMMMd().add_jm();
                return Column(
                  children: [
                    for (final e in items)
                      Card(
                        child: ListTile(
                          title: Text(e.buyerName ?? 'A buyer'),
                          subtitle: Text(
                            [
                              e.message,
                              if (e.contactPhone != null)
                                'Phone: ${e.contactPhone}',
                              stamp.format(e.createdAt.toLocal()),
                            ].join('\n'),
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () => setState(() => _enquiries =
                          widget.service.enquiriesFor(widget.listing.id)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
