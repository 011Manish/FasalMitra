import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/catalog_product.dart';
import '../services/catalog_service.dart';
import '../services/link_launcher.dart';
import '../widgets/figma_icons.dart';

const _maxMessageLength = 1000;
const _maxPhoneLength = 20;

bool _present(String? value) => value != null && value.trim().isNotEmpty;

String? _dialNumber(String? raw) {
  final cleaned = raw?.replaceAll(RegExp(r'[^0-9+]'), '');
  return cleaned == null || cleaned.isEmpty ? null : cleaned;
}

String _priceLabel(CatalogProduct p) {
  final price = p.indicativePrice;
  if (price == null) return 'Indicative price: not listed';
  final unit = _present(p.unit) ? ' / ${p.unit}' : '';
  return 'Indicative price: ${p.currency} '
      '${NumberFormat('#,##0.##').format(price)}$unit';
}

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, this.iconSize = 24});

  final String? url;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final uri = parseHttpsUrl(url);
    final fallback = Center(
      child: FIcon(
        Icons.image_outlined,
        size: iconSize,
        color: scheme.onSurfaceVariant,
      ),
    );
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: uri == null
          ? fallback
          : Image.network(
              uri.toString(),
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Center(
                      child: SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.service,
  });

  final CatalogProduct product;
  final CatalogService service;

  bool get _canCall =>
      !product.isDemo && _dialNumber(product.sellerPhone) != null;

  Future<void> _call(BuildContext context) async {
    final number = _dialNumber(product.sellerPhone);
    if (number == null) return;
    final opened = await openExternally(Uri(scheme: 'tel', path: number));
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not open the phone app. Seller number: ${product.sellerPhone}',
        ),
      ),
    );
  }

  Future<void> _enquire(BuildContext context) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EnquirySheet(service: service, product: product),
    );
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry sent')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ProductImage(url: product.imageUrl, iconSize: 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(product.name, style: textTheme.headlineSmall),
                  if (_present(product.nameNe))
                    Text(product.nameNe!, style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _ProductChips(product: product),
                  const SizedBox(height: 12),
                  Text(_priceLabel(product), style: textTheme.titleMedium),
                  if (_present(product.description)) ...[
                    const SizedBox(height: 16),
                    Text(product.description!, style: textTheme.bodyLarge),
                  ],
                  if (_present(product.sellerName) ||
                      _present(product.sellerPhone) ||
                      _present(product.sellerAddress)) ...[
                    const SizedBox(height: 24),
                    _SellerBlock(product: product),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => _enquire(context),
                    icon: const FIcon(Icons.mail_outline),
                    label: const Text('Send enquiry'),
                  ),
                  if (_canCall) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _call(context),
                      icon: const FIcon(Icons.call_outlined),
                      label: const Text('Call seller'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductChips extends StatelessWidget {
  const _ProductChips({required this.product});
  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    final (availabilityBg, availabilityFg) = switch (product.availability) {
      'out_of_stock' => (scheme.errorContainer, scheme.onErrorContainer),
      'limited' => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      _ => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        Chip(
          label: Text(
            catalogCategoryLabels[product.category] ?? product.category,
          ),
        ),
        Chip(
          label: Text(
            catalogAvailabilityLabels[product.availability] ??
                product.availability,
            style: labelStyle?.copyWith(color: availabilityFg),
          ),
          backgroundColor: availabilityBg,
          side: BorderSide.none,
        ),
        if (product.isDemo) const Chip(label: Text('Sample product')),
      ],
    );
  }
}

class _SellerBlock extends StatelessWidget {
  const _SellerBlock({required this.product});
  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seller', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (_present(product.sellerName))
          _SellerLine(
              icon: Icons.storefront_outlined, text: product.sellerName!),
        if (_present(product.sellerPhone))
          _SellerLine(icon: Icons.phone_outlined, text: product.sellerPhone!),
        if (_present(product.sellerAddress))
          _SellerLine(
            icon: Icons.location_on_outlined,
            text: product.sellerAddress!,
          ),
      ],
    );
  }
}

class _SellerLine extends StatelessWidget {
  const _SellerLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FIcon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _EnquirySheet extends StatefulWidget {
  const _EnquirySheet({required this.service, required this.product});

  final CatalogService service;
  final CatalogProduct product;

  @override
  State<_EnquirySheet> createState() => _EnquirySheetState();
}

class _EnquirySheetState extends State<_EnquirySheet> {
  final _message = TextEditingController();
  final _phone = TextEditingController();
  bool _sending = false;
  String? _messageError;
  String? _sendError;

  @override
  void dispose() {
    _message.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _message.text.trim();
    if (message.isEmpty) {
      setState(() => _messageError = 'Please write a message.');
      return;
    }
    final phone = _phone.text.trim();
    setState(() {
      _sending = true;
      _messageError = null;
      _sendError = null;
    });
    try {
      await widget.service.sendEnquiry(
        productId: widget.product.id,
        message: message,
        phone: phone.isEmpty ? null : phone,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendError =
            'Could not send your enquiry. Check your internet and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enquiry about ${widget.product.name}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              enabled: !_sending,
              maxLength: _maxMessageLength,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Message',
                errorText: _messageError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              enabled: !_sending,
              maxLength: _maxPhoneLength,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            if (_sendError != null) ...[
              const SizedBox(height: 8),
              Text(
                _sendError!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
