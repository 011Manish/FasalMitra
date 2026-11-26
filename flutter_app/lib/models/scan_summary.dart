import '../l10n/app_lang.dart';
import 'plant_scan.dart';

/// What the scan screens show for one scan: the four things in the Figma
/// design (issue, confidence, what we found, recommended action) plus the
/// extra report details the backend returns.
class ScanSummary {
  const ScanSummary({
    required this.issue,
    required this.confidence,
    required this.summary,
    required this.action,
    this.hasFullReport = false,
    this.growthStage,
    this.treatmentPlan = const [],
    this.dosage,
    this.organicAlternatives = const [],
    this.prevention = const [],
    this.recovery,
  });

  final String issue;

  /// 'high', 'medium' or 'low'
  final String confidence;
  final String summary;
  final String action;
  final bool hasFullReport;
  final String? growthStage;
  final List<String> treatmentPlan;
  final String? dosage;
  final List<String> organicAlternatives;
  final List<String> prevention;
  final String? recovery;

  /// Low confidence shows the "Result unclear" layout.
  bool get isUncertain => confidence == 'low';

  /// Sample content for the DEMO layout, shown only while the AI service has
  /// no API key. It is never saved.
  static ScanSummary demo() => ScanSummary(
        issue: tr('Leaf blight (sample)'),
        confidence: 'medium',
        summary: tr(
            'Brown spots with yellow edges on the leaf. This is sample text to show the layout.'),
        action: tr(
            'Remove affected leaves and keep the leaves dry. Ask a local agricultural expert before using any spray.'),
      );

  factory ScanSummary.fromScan(PlantScan scan) {
    final a = scan.analysis;
    final confidence = _confidence(scan.confidenceLevel);
    final summaryText = (a['summary'] ?? '').toString().trim();
    final full = a['health_score'] is num;

    if (!full) {
      // Pl@ntNet-only result: it names a possible problem but gives no plan.
      final matches = (a['plantnet'] as List? ?? []).whereType<Map>().toList();
      final top = matches.isEmpty ? null : matches.first;
      final label = top == null ? null : top['label']?.toString();
      return ScanSummary(
        issue: (label == null || label.isEmpty)
            ? tr('No known problem matched')
            : label,
        confidence: confidence,
        summary: summaryText,
        action:
            tr('Ask a local agricultural expert before using any treatment.'),
      );
    }

    final disease = _map(a['disease_or_pest']);
    final nutrient = _map(a['nutrient_deficiency']);
    final plan = _strings(a['treatment_plan']);

    String issue;
    if (disease['detected'] == true) {
      issue = _clean(disease['name']) ?? tr('Unspecified problem');
    } else if (nutrient['detected'] == true) {
      final n = _clean(nutrient['nutrient']);
      issue = n == null
          ? tr('Nutrient deficiency')
          : '${tr('Nutrient deficiency')}: $n';
    } else {
      issue = tr('No disease detected');
    }

    String action;
    if (plan.isNotEmpty) {
      action = plan.take(2).join(' ');
    } else if (disease['detected'] == true || nutrient['detected'] == true) {
      action =
          tr('Ask a local agricultural expert before using any treatment.');
    } else {
      action = tr('No treatment needed. Keep monitoring your crop.');
    }

    return ScanSummary(
      issue: issue,
      confidence: confidence,
      summary: summaryText.isEmpty ? tr('No summary available.') : summaryText,
      action: action,
      hasFullReport: true,
      growthStage: _clean(a['growth_stage']),
      treatmentPlan: plan,
      dosage: _usefulText(a['dosage_guidance']),
      organicAlternatives: _strings(a['organic_alternatives']),
      prevention: _strings(a['prevention_steps']),
      recovery: _usefulText(a['estimated_recovery_time']),
    );
  }

  static String _confidence(String raw) {
    final v = raw.toLowerCase();
    return (v == 'high' || v == 'medium' || v == 'low') ? v : 'low';
  }

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static List<String> _strings(Object? v) => v is List
      ? v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
      : <String>[];

  static String? _clean(Object? v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty || s == 'null') ? null : s;
  }

  /// Drops "not applicable" style answers so they are not shown as a card.
  static String? _usefulText(Object? v) {
    final s = _clean(v);
    if (s == null) return null;
    final lower = s.toLowerCase();
    if (lower == 'not applicable' || lower == 'n/a' || lower == 'none') {
      return null;
    }
    return s;
  }
}
