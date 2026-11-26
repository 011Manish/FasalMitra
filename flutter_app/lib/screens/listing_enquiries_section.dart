import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import '../widgets/figma_icons.dart';

class RetryMessage extends StatelessWidget {
  const RetryMessage({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class ListingEnquiriesSection extends StatefulWidget {
  const ListingEnquiriesSection(
      {super.key, required this.service, required this.listingId});
  final MarketplaceService service;
  final String listingId;

  @override
  State<ListingEnquiriesSection> createState() =>
      _ListingEnquiriesSectionState();
}

class _ListingEnquiriesSectionState extends State<ListingEnquiriesSection> {
  late Future<List<ListingEnquiry>> _load =
      widget.service.enquiriesFor(widget.listingId);
  String? _updatingId;

  void _snack(String message, {VoidCallback? onRetry}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      action: onRetry == null
          ? null
          : SnackBarAction(label: 'Retry', onPressed: onRetry),
    ));
  }

  void _reload() =>
      setState(() => _load = widget.service.enquiriesFor(widget.listingId));

  Future<void> _setStatus(ListingEnquiry enquiry, String status) async {
    setState(() => _updatingId = enquiry.id);
    try {
      await widget.service.setEnquiryStatus(enquiry.id, status);
      if (!mounted) return;
      _snack('Enquiry updated.');
      _reload();
    } catch (e) {
      _snack(
        marketplaceErrorMessage(e, fallback: 'Could not update the enquiry.'),
        onRetry: () => _setStatus(enquiry, status),
      );
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text('Enquiries', style: theme.textTheme.titleMedium)),
            IconButton(
              icon: const FIcon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _reload,
            ),
          ],
        ),
        FutureBuilder<List<ListingEnquiry>>(
          future: _load,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return RetryMessage(
                message: marketplaceErrorMessage(snap.error!,
                    fallback: 'Could not load enquiries.'),
                onRetry: _reload,
              );
            }
            final items = snap.data ?? const <ListingEnquiry>[];
            if (items.isEmpty) return const Text('No enquiries yet.');
            return Column(
              children: [for (final e in items) _card(e, theme)],
            );
          },
        ),
      ],
    );
  }

  Widget _card(ListingEnquiry e, ThemeData theme) {
    final busy = _updatingId != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(e.buyerName ?? 'A buyer',
                      style: theme.textTheme.titleSmall),
                ),
                Chip(label: Text(e.statusLabel)),
              ],
            ),
            const SizedBox(height: 4),
            Text(e.message),
            if (e.contactPhone case final String phone when phone.isNotEmpty)
              Text('Phone: $phone'),
            Text(DateFormat.yMMMd().add_jm().format(e.createdAt.toLocal()),
                style: theme.textTheme.bodySmall),
            if (e.status != EnquiryStatus.closed) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (e.status == EnquiryStatus.received)
                    FilledButton.tonal(
                      onPressed: busy
                          ? null
                          : () => _setStatus(e, EnquiryStatus.contacted),
                      child: const Text('Mark contacted'),
                    ),
                  OutlinedButton(
                    onPressed:
                        busy ? null : () => _setStatus(e, EnquiryStatus.closed),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
