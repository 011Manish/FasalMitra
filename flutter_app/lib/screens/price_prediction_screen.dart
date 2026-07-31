import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/price_trend.dart';
import '../services/price_prediction_service.dart';

class PricePredictionScreen extends StatefulWidget {
  const PricePredictionScreen({super.key});

  @override
  State<PricePredictionScreen> createState() => _PricePredictionScreenState();
}

class _PricePredictionScreenState extends State<PricePredictionScreen> {
  final _service = PricePredictionService(Supabase.instance.client);
  late Future<List<String>> _crops;
  String? _selected;
  Future<PriceTrend>? _trend;

  @override
  void initState() {
    super.initState();
    _crops = _service.listCrops().then((c) {
      if (c.isNotEmpty) _selectCrop(c.first);
      return c;
    });
  }

  void _selectCrop(String crop) {
    setState(() {
      _selected = crop;
      _trend = _service.fetchTrend(crop);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rs =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 1);

    return Scaffold(
      appBar: AppBar(title: const Text('Price prediction')),
      body: FutureBuilder<List<String>>(
        future: _crops,
        builder: (context, cropsSnap) {
          if (cropsSnap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (cropsSnap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load: ${cropsSnap.error}'),
            );
          }
          final crops = cropsSnap.data!;
          if (crops.isEmpty) {
            return const Center(child: Text('No price data available yet.'));
          }
          return Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    for (final c in crops)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: _selected == c,
                          onSelected: (_) => _selectCrop(c),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<PriceTrend>(
                  future: _trend,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Could not load: ${snap.error}'),
                      );
                    }
                    final trend = snap.data!;
                    if (trend.points.isEmpty) {
                      return const Center(
                          child: Text('No price history for this crop yet.'));
                    }
                    final icon = switch (trend.direction) {
                      TrendDirection.up => Icons.trending_up,
                      TrendDirection.down => Icons.trending_down,
                      TrendDirection.stable => Icons.trending_flat,
                    };
                    final color = switch (trend.direction) {
                      TrendDirection.up => Colors.green,
                      TrendDirection.down => Colors.red,
                      TrendDirection.stable => Colors.grey,
                    };
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: color, size: 32),
                            const SizedBox(width: 8),
                            Text(
                              '${trend.percentChange >= 0 ? '+' : ''}${trend.percentChange.toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: color),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(trend.sellHint),
                        const SizedBox(height: 16),
                        Text(
                            'Next week estimate: ${rs.format(trend.nextEstimate)}/kg',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 220,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    for (var i = 0;
                                        i < trend.points.length;
                                        i++)
                                      FlSpot(i.toDouble(),
                                          trend.points[i].avgPrice),
                                  ],
                                  isCurved: true,
                                  color: color,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Based on Kalimati Market historical data.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
