import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;

  late Future<List<String>> _photoUrls = _loadPhotoUrls();

  bool get _isMine => widget.listing.sellerId == widget.service.currentUserId;

  @override
  void dispose() {
    _message.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _snack(String message, {VoidCallback? onRetry}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      action: onRetry == null
          ? null
          : SnackBarAction(label: 'Retry', onPressed: onRetry),
    ));
  }

  Future<List<String>> _loadPhotoUrls() async {
    final photos = await widget.service.photos(widget.listing.id);
    return Future.wait(
        photos.map((p) => widget.service.signedUrl(p.storagePath)));
  }

  void _reloadPhotos() => setState(() => _photoUrls = _loadPhotoUrls());

  Future<void> _sendEnquiry() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final phone = _phone.text.trim();
      await widget.service.sendEnquiry(
        listingId: widget.listing.id,
        message: _message.text.trim(),
        phone: phone.isEmpty ? null : phone,
      );
      if (!mounted) return;
      _message.clear();
      _snack('Enquiry sent to the seller.');
    } catch (e) {
      _snack(
        marketplaceErrorMessage(
          e,
          fallback: 'Could not send your enquiry.',
          denied: 'This listing is no longer available for enquiries.',
        ),
        onRetry: _sendEnquiry,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final theme = Theme.of(context);
    final description = l.description;

    return Scaffold(
      appBar: AppBar(title: Text(l.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PhotoStrip(urls: _photoUrls, onRetry: _reloadPhotos),
          Text('${l.currency} ${l.price.toStringAsFixed(2)} / ${l.unit}',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('${l.quantityLabel} available',
              style: theme.textTheme.bodyLarge),
          if (l.locationText.isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow(icon: Icons.place_outlined, text: l.locationText),
          ],
          if (l.availableFrom != null) ...[
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.event_outlined,
              text:
                  'Available from ${DateFormat.yMMMd().format(l.availableFrom!)}',
            ),
          ],
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(description),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            Chip(label: Text(l.statusLabel)),
            if (l.isHidden && _isMine)
              const Chip(label: Text('Hidden by an admin')),
          ]),
          const SizedBox(height: 16),
          if (_isMine)
            const Text(
                'Manage this listing and read its enquiries from My listings.')
          else if (l.isActive)
            _buildEnquiryForm(theme)
          else
            const Text('This listing is no longer available for enquiries.'),
        ],
      ),
    );
  }

  Widget _buildEnquiryForm(ThemeData theme) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact the seller', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _message,
            maxLines: 3,
            validator: validateEnquiryMessage,
            decoration: const InputDecoration(
              labelText: 'Your message',
              hintText: 'Ask about price, quantity or pickup',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
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
            child: Text(_busy ? 'Sending...' : 'Send enquiry'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18),
      const SizedBox(width: 4),
      Expanded(child: Text(text)),
    ]);
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.urls, required this.onRetry});
  final Future<List<String>> urls;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: urls,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Row(children: [
            const Expanded(child: Text('Photos could not be loaded.')),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ]);
        }
        final list = snap.data ?? const <String>[];
        if (list.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  list[i],
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 200,
                    height: 200,
                    alignment: Alignment.center,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
