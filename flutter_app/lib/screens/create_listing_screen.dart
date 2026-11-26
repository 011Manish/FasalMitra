import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import '../services/photo_service.dart' show maxPhotoBytes;
import '../widgets/figma_icons.dart';

const _maxPhotos = 4;

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key, required this.service, this.existing});
  final MarketplaceService service;
  final MarketplaceListing? existing;

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _form = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _unit;
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  late final TextEditingController _stateProvince;
  late final TextEditingController _district;
  late final TextEditingController _municipality;
  late final List<String> _currencyOptions;
  late DateTime _availableFrom;
  late String _currency;

  final List<File> _photos = [];
  int _existingPhotoCount = 0;
  MarketplaceListing? _saved;
  String? _photoProblem;
  bool _busy = false;

  bool get _isEdit => widget.existing != null;
  int get _photoRoom => _maxPhotos - _existingPhotoCount - _photos.length;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title);
    _description = TextEditingController(text: e?.description);
    _unit = TextEditingController(text: e?.unit ?? 'kg');
    _quantity = TextEditingController(
        text: e == null ? null : formatNumber(e.quantity));
    _price =
        TextEditingController(text: e == null ? null : formatNumber(e.price));
    _stateProvince = TextEditingController(text: e?.stateProvince);
    _district = TextEditingController(text: e?.district);
    _municipality = TextEditingController(text: e?.municipality);
    _availableFrom = e?.availableFrom ?? DateTime.now();
    _currency = e?.currency ?? listingCurrencies.first;
    _currencyOptions = {...listingCurrencies, _currency}.toList();
    if (e != null) _loadExistingPhotoCount();
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _unit,
      _quantity,
      _price,
      _stateProvince,
      _district,
      _municipality,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _textOrNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
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

  void _finish() => Navigator.pop(context, true);

  Future<void> _loadExistingPhotoCount() async {
    try {
      final photos = await widget.service.photos(widget.existing!.id);
      if (!mounted) return;
      setState(() => _existingPhotoCount = photos.length);
    } catch (e) {
      _snack(marketplaceErrorMessage(e,
          fallback: 'Could not load the current photos.'));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final earliest = now.subtract(const Duration(days: 1));
    final latest = now.add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      firstDate: _availableFrom.isBefore(earliest) ? _availableFrom : earliest,
      lastDate: _availableFrom.isAfter(latest) ? _availableFrom : latest,
      initialDate: _availableFrom,
    );
    if (picked == null || !mounted) return;
    setState(() => _availableFrom = picked);
  }

  Future<void> _addPhotos() async {
    final room = _photoRoom;
    if (room <= 0) {
      _snack('You can add up to $_maxPhotos photos.');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const FIcon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const FIcon(Icons.photo_library_outlined),
              title: const Text('Pick from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = <XFile>[];
    if (source == ImageSource.camera) {
      final x = await _picker.pickImage(source: source, imageQuality: 85);
      if (x != null) picked.add(x);
    } else {
      picked.addAll(await _picker.pickMultiImage(imageQuality: 85));
    }

    final added = <File>[];
    var tooBig = 0;
    var unsupported = 0;
    for (final x in picked.take(room)) {
      final f = File(x.path);
      if (photoExtension(f.path) == null) {
        unsupported++;
      } else if (await f.length() > maxPhotoBytes) {
        tooBig++;
      } else {
        added.add(f);
      }
    }
    if (!mounted) return;
    setState(() => _photos.addAll(added));
    final notes = [
      if (tooBig > 0) '$tooBig photo(s) skipped: each must be under 5 MB.',
      if (unsupported > 0)
        '$unsupported photo(s) skipped: use JPG, PNG or WebP.',
      if (picked.length > room) 'Only $room more photo(s) fit.',
    ];
    if (notes.isNotEmpty) _snack(notes.join(' '));
  }

  MarketplaceListing _buildListing() {
    final base = widget.existing;
    return MarketplaceListing(
      id: base?.id ?? '',
      sellerId: base?.sellerId ?? '',
      farmId: base?.farmId,
      title: _title.text.trim(),
      description: _textOrNull(_description),
      unit: _unit.text.trim(),
      quantity: double.parse(_quantity.text.trim()),
      price: double.parse(_price.text.trim()),
      currency: _currency,
      status: base?.status ?? ListingStatus.active,
      createdAt: base?.createdAt ?? DateTime.now(),
      stateProvince: _textOrNull(_stateProvince),
      district: _textOrNull(_district),
      municipality: _textOrNull(_municipality),
      availableFrom: _availableFrom,
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final listing = _buildListing();
      _saved = _isEdit
          ? await widget.service.update(listing)
          : await widget.service.create(listing);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(
        marketplaceErrorMessage(e,
            fallback: _isEdit
                ? 'Could not save your changes.'
                : 'Could not publish the listing.'),
        onRetry: _submit,
      );
      return;
    }
    await _uploadPending();
  }

  Future<void> _uploadPending() async {
    final listing = _saved!;
    setState(() => _busy = true);
    final failed = <File>[];
    var reason = '';
    for (final f in _photos) {
      try {
        await widget.service.uploadPhoto(listingId: listing.id, file: f);
      } catch (e) {
        failed.add(f);
        reason = marketplaceErrorMessage(e,
            fallback: 'Check your internet and try again.');
      }
    }
    if (!mounted) return;
    if (failed.isEmpty) {
      _snack(_isEdit ? 'Listing updated.' : 'Listing published.');
      _finish();
      return;
    }
    setState(() {
      _photos
        ..clear()
        ..addAll(failed);
      _photoProblem = 'Your listing is ${_isEdit ? 'saved' : 'published'}, but '
          '${failed.length} photo(s) were not uploaded. $reason';
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _saved == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Edit listing' : 'Sell produce')),
        body: _saved == null ? _buildForm() : _buildPhotoRetry(),
      ),
    );
  }

  Widget _buildPhotoRetry() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_photoProblem ?? '', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _photos.length; i++)
              _PhotoThumb(
                file: _photos[i],
                onRemove:
                    _busy ? null : () => setState(() => _photos.removeAt(i)),
              ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy || _photos.isEmpty ? null : _uploadPending,
          child: Text(_busy ? 'Uploading...' : 'Retry photos'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy ? null : _finish,
          child: const Text('Finish without these photos'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _form,
        child: ListView(
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Crop name'),
              validator: validateRequired,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantity,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    validator: validatePositiveNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration:
                        const InputDecoration(labelText: 'Unit (kg, bag...)'),
                    validator: validateRequired,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Asking price per unit'),
                    validator: validatePositiveNumber,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: [
                      for (final c in _currencyOptions)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _currency = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Harvest / available from'),
                child: Text(DateFormat.yMMMd().format(_availableFrom)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _district,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'District'),
              validator: validateRequired,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _municipality,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Municipality / Village (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stateProvince,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'State / Province (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 16),
            Text('Photos (${_existingPhotoCount + _photos.length}/$_maxPhotos)',
                style: theme.textTheme.titleSmall),
            if (_existingPhotoCount > 0)
              Text('Photos already on this listing stay as they are.',
                  style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  _PhotoThumb(
                    file: _photos[i],
                    onRemove: _busy
                        ? null
                        : () => setState(() => _photos.removeAt(i)),
                  ),
                if (_photoRoom > 0)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _addPhotos,
                    icon: const FIcon(Icons.add_a_photo_outlined),
                    label: const Text('Add photos'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy
                  ? (_isEdit ? 'Saving...' : 'Publishing...')
                  : (_isEdit ? 'Save changes' : 'Publish listing')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.file, required this.onRemove});
  final File file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, width: 88, height: 88, fit: BoxFit.cover),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: InkWell(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 12,
              child: FIcon(Icons.close, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
