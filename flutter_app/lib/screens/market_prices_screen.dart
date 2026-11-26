import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crop_price_point.dart';
import '../services/price_prediction_service.dart';

final _rs =
    NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 1);

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  final _service = PricePredictionService(Supabase.instance.client);
  List<CropPricePoint>? _rows;
  bool _failed = false;
  String? _crop;
  String? _market;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _service.fetchLatestPrices();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _failed = false;
        if (!rows.any((p) => p.cropName == _crop)) _crop = null;
        if (!rows.any((p) => marketLabel(p) == _market)) _market = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() {
      _failed = false;
      _rows = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Price list')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_failed) {
      return _ErrorView(
        message: 'Could not load prices. Check your internet.',
        onRetry: _retry,
      );
    }
    final rows = _rows;
    if (rows == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: const _EmptyMessage('No price data available yet.'),
      );
    }
    final visible = rows
        .where((p) =>
            (_crop == null || p.cropName == _crop) &&
            (_market == null || marketLabel(p) == _market))
        .toList();
    return Column(
      children: [
        if (visible.any((p) => p.isDemo)) const _DemoBanner(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Crop',
                  allLabel: 'All crops',
                  options: (rows.map((p) => p.cropName).toSet().toList()
                    ..sort()),
                  value: _crop,
                  onChanged: (v) => setState(() => _crop = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterDropdown(
                  label: 'Market',
                  allLabel: 'All markets',
                  options: (rows.map(marketLabel).toSet().toList()..sort()),
                  value: _market,
                  onChanged: (v) => setState(() => _market = v),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: visible.isEmpty
                ? const _EmptyMessage('No prices match these filters.')
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: visible.length,
                    itemBuilder: (context, i) => _PriceTile(point: visible[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Sample data: not live market prices.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onTertiaryContainer,
            ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.allLabel,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String allLabel;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: value,
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(allLabel)),
            for (final option in options)
              DropdownMenuItem<String?>(
                value: option,
                child: Text(option, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  const _PriceTile({required this.point});

  final CropPricePoint point;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = point.source.isEmpty
        ? point.source
        : point.source[0].toUpperCase() + point.source.substring(1);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child:
                      Text(point.cropName, style: theme.textTheme.titleMedium),
                ),
                if (point.isDemo)
                  Chip(
                    label: const Text('DEMO'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                  ),
              ],
            ),
            Text(marketLabel(point), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('${_rs.format(point.avgPrice)} ${point.unit}',
                style: theme.textTheme.titleLarge),
            Text(
              'Range: ${_rs.format(point.minPrice)} to ${_rs.format(point.maxPrice)}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Source: $source. Price date: '
              '${DateFormat.yMMMd().format(point.recordedDate)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [Text(message, textAlign: TextAlign.center)],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
