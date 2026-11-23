import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/plant_scan.dart';
import '../services/plant_scan_service.dart';
import 'plant_scan_followup_chat_screen.dart';

class PlantScanResultScreen extends StatefulWidget {
  const PlantScanResultScreen.newScan({
    super.key,
    required String this.farmId,
    required String this.storagePath,
  }) : existingScan = null;

  const PlantScanResultScreen.existing({super.key, required PlantScan scan})
      : existingScan = scan,
        farmId = null,
        storagePath = null;

  final String? farmId;
  final String? storagePath;
  final PlantScan? existingScan;

  @override
  State<PlantScanResultScreen> createState() => _PlantScanResultScreenState();
}

class _PlantScanResultScreenState extends State<PlantScanResultScreen> {
  late final _scans = PlantScanService(Supabase.instance.client);
  late Future<PlantScan> _future;

  @override
  void initState() {
    super.initState();
    _future = _runAnalysis();
  }

  Future<PlantScan> _runAnalysis() {
    if (widget.existingScan != null) return Future.value(widget.existingScan);
    return _scans.analyze(
        farmId: widget.farmId!, storagePath: widget.storagePath!);
  }

  void _retry() => setState(() => _future = _runAnalysis());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant health report')),
      body: FutureBuilder<PlantScan>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing your photo… this takes a few seconds.'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(plantScanErrorMessage(snapshot.error!),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                        onPressed: _retry, child: const Text('Try again')),
                  ],
                ),
              ),
            );
          }

          return _ReportBody(scan: snapshot.data!);
        },
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.scan});
  final PlantScan scan;

  @override
  Widget build(BuildContext context) {
    final a = scan.analysis;
    final disease = a['disease_or_pest'] as Map<String, dynamic>? ?? {};
    final nutrient = a['nutrient_deficiency'] as Map<String, dynamic>? ?? {};
    final treatmentPlan = (a['treatment_plan'] as List? ?? []).cast<String>();
    final organicAlts =
        (a['organic_alternatives'] as List? ?? []).cast<String>();
    final prevention = (a['prevention_steps'] as List? ?? []).cast<String>();
    final healthScore = a['health_score'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ScoreHeader(score: healthScore, confidence: scan.confidenceLevel),
        const SizedBox(height: 8),
        if (a['summary'] != null)
          _Section(title: 'Summary', body: a['summary'].toString()),
        _Section(
          title: 'Growth stage',
          body: (a['growth_stage'] ?? 'Not determined').toString(),
        ),
        _Section(
          title: 'Disease / pest',
          body: (disease['detected'] == true)
              ? '${disease['name'] ?? 'Unspecified'} — ${disease['details'] ?? ''}'
              : 'None detected.',
        ),
        _Section(
          title: 'Nutrient deficiency',
          body: (nutrient['detected'] == true)
              ? '${nutrient['nutrient'] ?? 'Unspecified'} — ${nutrient['details'] ?? ''}'
              : 'None detected.',
        ),
        if (treatmentPlan.isNotEmpty)
          _ListSection(title: 'Treatment plan', items: treatmentPlan),
        _Section(
            title: 'Dosage guidance',
            body: (a['dosage_guidance'] ?? 'Not applicable').toString()),
        if (organicAlts.isNotEmpty)
          _ListSection(title: 'Organic alternatives', items: organicAlts),
        if (prevention.isNotEmpty)
          _ListSection(title: 'Prevention', items: prevention),
        _Section(
          title: 'Estimated recovery time',
          body: (a['estimated_recovery_time'] ?? 'Not applicable').toString(),
        ),
        const SizedBox(height: 12),
        _Disclaimer(),
        if (enableFollowUpChat) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.chat_outlined),
            label: const Text('More inquiry'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlantScanFollowUpChatScreen(scan: scan),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.score, required this.confidence});
  final int score;
  final String confidence;

  Color _scoreColor() {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _scoreColor().withValues(alpha: 0.15),
              child: Text('$score',
                  style: TextStyle(
                      color: _scoreColor(), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall health score',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                      'Confidence: ${confidence[0].toUpperCase()}${confidence.substring(1)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(body),
          ],
        ),
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...items.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('•  $i'),
                )),
          ],
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This is an AI estimate, not a confirmed diagnosis. '
              'For serious or persistent problems, consult a local agricultural expert.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
