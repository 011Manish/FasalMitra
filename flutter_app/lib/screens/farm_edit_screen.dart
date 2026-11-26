import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/farm_profile.dart';
import '../services/farm_service.dart';
import '../widgets/figma_icons.dart';

class FarmEditScreen extends StatefulWidget {
  const FarmEditScreen({super.key, required this.service, this.existing});
  final FarmService service;
  final FarmProfile? existing;

  @override
  State<FarmEditScreen> createState() => _FarmEditScreenState();
}

class _FarmEditScreenState extends State<FarmEditScreen> {
  final _form = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _size = TextEditingController(
      text:
          (widget.existing?.landSizeValue ?? widget.existing?.landSizeHectares)
                  ?.toString() ??
              '');
  late final _stateProvince =
      TextEditingController(text: widget.existing?.stateProvince ?? '');
  late final _district =
      TextEditingController(text: widget.existing?.district ?? '');
  late final _municipality =
      TextEditingController(text: widget.existing?.municipality ?? '');

  late String _crop = widget.existing?.cropType ?? cropTypes.first;
  late String _unit = widget.existing?.landUnit ?? 'hectare';
  late String _soil = widget.existing?.soilType ?? soilTypes.first;
  late String _irrig =
      widget.existing?.irrigationSystem ?? irrigationSystems.first;
  late DateTime _plantedOn = widget.existing?.plantationDate ?? DateTime.now();

  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _size, _stateProvince, _district, _municipality]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Trimmed text, or null when empty so the database stores NULL, not ''.
  String? _textOrNull(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  double _hectares(double entered) =>
      double.parse((entered * landUnitToHectares[_unit]!).toStringAsFixed(3));

  String? _validateSize(String? value) {
    final entered = double.tryParse(value?.trim() ?? '');
    if (entered == null || entered <= 0) return 'Enter a positive number';
    final hectares = _hectares(entered);
    if (hectares <= 0) return 'Land size is too small';
    if (hectares > 10000) return 'Land size is too large';
    return null;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate:
          _plantedOn.isAfter(DateTime.now()) ? DateTime.now() : _plantedOn,
    );
    if (picked != null && mounted) setState(() => _plantedOn = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);

    try {
      final entered = double.parse(_size.text.trim());
      final farm = FarmProfile(
        id: widget.existing?.id ?? '',
        userId: '',
        name: _name.text.trim(),
        cropType: _crop,
        landSizeHectares: _hectares(entered),
        landSizeValue: entered,
        landUnit: _unit,
        plantationDate: _plantedOn,
        soilType: _soil,
        irrigationSystem: _irrig,
        stateProvince: _textOrNull(_stateProvince),
        district: _textOrNull(_district),
        municipality: _textOrNull(_municipality),
      );

      if (widget.existing == null) {
        await widget.service.create(farm);
      } else {
        await widget.service.update(widget.existing!.id, {
          'name': farm.name,
          'crop_type': farm.cropType,
          'land_size_hectares': farm.landSizeHectares,
          'land_size_value': farm.landSizeValue,
          'land_unit': farm.landUnit,
          'plantation_date':
              farm.plantationDate.toIso8601String().substring(0, 10),
          'soil_type': farm.soilType,
          'irrigation_system': farm.irrigationSystem,
          'state_province': farm.stateProvince,
          'district': farm.district,
          'municipality': farm.municipality,
        });
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _snack('Could not save the farm. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this farm?'),
        content: const Text('This will remove the farm profile.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await widget.service.delete(widget.existing!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      _snack('Could not delete the farm. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New farm' : 'Edit farm'),
        actions: [
          if (widget.existing != null)
            IconButton(
                onPressed: _busy ? null : _delete,
                tooltip: 'Delete farm',
                icon: const FIcon(Icons.delete_outline)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Farm name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _crop,
                decoration: const InputDecoration(labelText: 'Crop type'),
                items: cropTypes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _crop = v!),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _size,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Land size'),
                      validator: _validateSize,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: landUnitToHectares.keys
                          .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: 'Plantation date'),
                  child: Text(df.format(_plantedOn)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _soil,
                decoration: const InputDecoration(labelText: 'Soil type'),
                items: soilTypes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _soil = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _irrig,
                decoration:
                    const InputDecoration(labelText: 'Irrigation system'),
                items: irrigationSystems
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _irrig = v!),
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
                controller: _district,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'District'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _municipality,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Municipality / Village (optional)'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(
                    widget.existing == null ? 'Create farm' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
