import 'package:flutter/material.dart';

import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key, required this.service});
  final MarketplaceService service;

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _unit = TextEditingController(text: 'kg');
  final _quantity = TextEditingController();
  final _price = TextEditingController();

  String _category = listingCategories.first;
  String _type = 'fixed_price';
  DateTime _auctionEndAt = DateTime.now().add(const Duration(days: 3));
  bool _busy = false;

  Future<void> _pickAuctionEnd() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDate: _auctionEndAt,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_auctionEndAt),
    );
    if (time == null) return;
    setState(() {
      _auctionEndAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final listing = MarketplaceListing(
        id: '',
        sellerId: '',
        listingType: _type,
        itemCategory: _category,
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        unit: _unit.text.trim(),
        quantity: double.parse(_quantity.text.trim()),
        price: double.parse(_price.text.trim()),
        currency: 'NPR',
        auctionEndAt: _type == 'auction' ? _auctionEndAt : null,
        status: 'active',
        createdAt: DateTime.now(),
      );
      await widget.service.create(listing);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not create listing: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New listing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'fixed_price', label: Text('Fixed price')),
                  ButtonSegment(value: 'auction', label: Text('Auction')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: listingCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(listingCategoryLabels[c] ?? c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (v) {
                        final parsed = double.tryParse(v?.trim() ?? '');
                        if (parsed == null || parsed <= 0) return 'Enter a positive number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unit,
                      decoration: const InputDecoration(labelText: 'Unit (kg, bag...)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _type == 'auction' ? 'Starting price (NPR)' : 'Price per unit (NPR)',
                ),
                validator: (v) {
                  final parsed = double.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed <= 0) return 'Enter a positive number';
                  return null;
                },
              ),
              if (_type == 'auction') ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickAuctionEnd,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Auction ends'),
                    child: Text(
                      '${_auctionEndAt.toLocal()}'.substring(0, 16),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Publish listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
