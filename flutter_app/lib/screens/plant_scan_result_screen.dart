import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_lang.dart';
import '../models/plant_scan.dart';
import '../models/scan_summary.dart';
import '../services/plant_scan_service.dart';
import '../widgets/figma_icons.dart';
import '../widgets/scan_kit.dart';
import 'camera_choice_screen.dart';
import 'plant_scan_followup_chat_screen.dart';

enum _Stage { processing, done, error }

/// The analysis step and its result (Figma: "Processing", "Scan Result",
/// "Scan Result - Demo", "Scan Result - Uncertain" and "Scan Error").
///
/// [PlantScanResultScreen.newScan] uploads and analyzes a photo, then shows
/// the result. [PlantScanResultScreen.existing] shows a saved scan from the
/// history list.
class PlantScanResultScreen extends StatefulWidget {
  const PlantScanResultScreen.newScan({
    super.key,
    this.farmId,
    required File this.file,
    this.source,
    this.onRetake,
  }) : existingScan = null;

  const PlantScanResultScreen.existing({super.key, required PlantScan scan})
      : existingScan = scan,
        farmId = null,
        file = null,
        source = null,
        onRetake = null;

  final String? farmId;
  final File? file;
  final ImageSource? source;
  final ValueChanged<ImageSource>? onRetake;
  final PlantScan? existingScan;

  @override
  State<PlantScanResultScreen> createState() => _PlantScanResultScreenState();
}

class _PlantScanResultScreenState extends State<PlantScanResultScreen> {
  late final _svc = PlantScanService(Supabase.instance.client);

  _Stage _stage = _Stage.processing;
  PlantScan? _scan;
  bool _demo = false;
  Object? _error;
  String? _storagePath;
  bool _saved = false;
  bool _cancelled = false;

  bool get _isExisting => widget.existingScan != null;

  @override
  void initState() {
    super.initState();
    if (_isExisting) {
      _scan = widget.existingScan;
      _stage = _Stage.done;
    } else {
      _run();
    }
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  void _retry() {
    setState(() {
      _stage = _Stage.processing;
      _error = null;
    });
    _run();
  }

  Future<void> _run() async {
    try {
      // Upload once. "Try again" reuses the same upload.
      _storagePath ??= await _svc.uploadScanPhoto(
        farmId: widget.farmId,
        file: widget.file!,
      );
      final scan = await _svc.analyze(
        farmId: widget.farmId,
        storagePath: _storagePath!,
      );
      if (!mounted || _cancelled) return;
      setState(() {
        _scan = scan;
        _stage = _Stage.done;
      });
    } catch (e) {
      if (!mounted || _cancelled) return;
      if (e is PlantScanFailed && e.reason == 'server_misconfigured') {
        // No AI key on the server yet: show the sample layout, clearly marked.
        setState(() {
          _demo = true;
          _stage = _Stage.done;
        });
      } else {
        setState(() {
          _error = e;
          _stage = _Stage.error;
        });
      }
    }
  }

  void _cancel() {
    _cancelled = true;
    Navigator.of(context).maybePop();
  }

  void _retake(ImageSource source) {
    final cb = widget.onRetake;
    if (cb == null) {
      popToScanCamera(context);
      return;
    }
    Navigator.of(context).pop();
    cb(source);
  }

  void _save() {
    // The backend already stores every finished scan, so this button only
    // confirms that it is in the history list.
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Saved to history'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context) => switch (_stage) {
        _Stage.processing => _buildProcessing(),
        _Stage.error => _buildError(),
        _Stage.done => _buildResult(),
      },
    );
  }

  // ---- Processing --------------------------------------------------------

  Widget _buildProcessing() {
    return ScanPage(
      onBack: _cancel,
      topGap: 70,
      children: [
        const Center(
          child: SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 5.5,
              color: ScanColors.greenDark,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          tr('Analyzing your photo…'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: ScanColors.ink,
          ),
        ),
        const SizedBox(height: 14),
        ScanSubtitle(tr('This can take a few seconds.'), center: true),
        const SizedBox(height: 56),
        ScanOutlineButton(label: tr('Cancel'), onPressed: _cancel),
      ],
    );
  }

  // ---- Error -------------------------------------------------------------

  Widget _buildError() {
    final err = _error;
    final message = err is PlantScanFailed
        ? tr(plantScanErrorMessage(err))
        : tr(
            "We couldn't analyze this photo. Check your connection and try again.");
    return ScanPage(
      topGap: 40,
      children: [
        const Center(child: ScanAlertBadge(iconName: 'alert')),
        const SizedBox(height: 12),
        Text(
          tr('Scan failed'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: ScanColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        ScanBanner(
          kind: ScanBannerKind.error,
          text: message,
          actionLabel: tr('Try again'),
          onAction: _retry,
        ),
        const SizedBox(height: 16),
        ScanPrimaryButton(label: tr('Try again'), onPressed: _retry),
        const SizedBox(height: 10),
        ScanOutlineButton(
          label: tr('Back to scan'),
          onPressed: () => popToScanCamera(context),
        ),
      ],
    );
  }

  // ---- Result ------------------------------------------------------------

  Widget _buildResult() {
    final scan = _scan;
    final summary = _demo || scan == null
        ? ScanSummary.demo()
        : ScanSummary.fromScan(scan);
    final uncertain = !_demo && summary.isUncertain;

    final photo = _ScanPhoto(
      file: widget.file,
      storagePath: scan?.photoStoragePath,
      service: _svc,
    );

    return ScanPage(
      children: [
        if (_demo) ...[
          ScanBanner(
            text: tr(
                'DEMO RESULT: this layout is a sample, not a real diagnosis.'),
          ),
          const SizedBox(height: 10),
        ] else if (uncertain) ...[
          ScanBanner(
            text: tr("We're not sure about this result. Try a clearer photo."),
          ),
          const SizedBox(height: 10),
        ],
        ScanTitle(
          uncertain ? tr('Result unclear') : tr('Scan result'),
          size: 25,
        ),
        const SizedBox(height: 12),
        photo,
        const SizedBox(height: 12),
        _FindingCard(
          label: uncertain ? tr('Possible issue') : tr('Detected issue'),
          issue: summary.issue,
          confidence: summary.confidence,
        ),
        if (summary.summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          ScanInfoCard(title: tr('What we found'), body: summary.summary),
        ],
        const SizedBox(height: 12),
        if (uncertain)
          ScanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('What to do next'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ScanColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('Retake the photo in daylight, closer to the affected leaf.'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: ScanColors.ink,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          ScanInfoCard(title: tr('Recommended action'), body: summary.action),
        ..._detailCards(summary),
        const SizedBox(height: 12),
        Text(
          tr('This is an AI estimate, not a confirmed diagnosis. For serious or persistent problems, consult a local agricultural expert.'),
          style: const TextStyle(
            fontSize: 12,
            color: ScanColors.body,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        if (uncertain) ...[
          ScanPrimaryButton(
            label: tr('Retake photo'),
            iconName: 'camera',
            onPressed: () => _retake(ImageSource.camera),
          ),
          const SizedBox(height: 10),
          ScanOutlineButton(
            label: tr('Upload a different photo'),
            iconName: 'upload',
            onPressed: () => _retake(ImageSource.gallery),
          ),
        ] else ...[
          if (!_isExisting && !_demo) ...[
            ScanPrimaryButton(
              label: _saved ? tr('Saved to history') : tr('Save to history'),
              onPressed: _saved ? null : _save,
            ),
            const SizedBox(height: 10),
          ],
          ScanOutlineButton(
            label: tr('Scan another crop'),
            iconName: 'scan',
            onPressed: () => popToScanCamera(context),
          ),
        ],
        if (enableFollowUpChat && summary.hasFullReport && scan != null) ...[
          const SizedBox(height: 10),
          ScanOutlineButton(
            label: tr('More inquiry'),
            icon: Icons.chat_outlined,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlantScanFollowUpChatScreen(scan: scan),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Extra report cards, in the same style as the three from the design.
  List<Widget> _detailCards(ScanSummary s) {
    if (!s.hasFullReport) return const [];
    Widget gap() => const SizedBox(height: 12);
    return [
      if (s.growthStage != null) ...[
        gap(),
        ScanInfoCard(title: tr('Growth stage'), body: s.growthStage!),
      ],
      if (s.treatmentPlan.isNotEmpty) ...[
        gap(),
        ScanListCard(title: tr('Treatment plan'), items: s.treatmentPlan),
      ],
      if (s.dosage != null) ...[
        gap(),
        ScanInfoCard(title: tr('Dosage guidance'), body: s.dosage!),
      ],
      if (s.organicAlternatives.isNotEmpty) ...[
        gap(),
        ScanListCard(
            title: tr('Organic alternatives'), items: s.organicAlternatives),
      ],
      if (s.prevention.isNotEmpty) ...[
        gap(),
        ScanListCard(title: tr('Prevention'), items: s.prevention),
      ],
      if (s.recovery != null) ...[
        gap(),
        ScanInfoCard(title: tr('Estimated recovery time'), body: s.recovery!),
      ],
    ];
  }
}

/// "Detected issue / disease name / Confidence + tag" card.
class _FindingCard extends StatelessWidget {
  const _FindingCard({
    required this.label,
    required this.issue,
    required this.confidence,
  });

  final String label;
  final String issue;
  final String confidence;

  @override
  Widget build(BuildContext context) {
    return ScanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: ScanColors.body),
          ),
          const SizedBox(height: 8),
          Text(
            issue,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ScanColors.ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                tr('Confidence'),
                style: const TextStyle(fontSize: 13, color: ScanColors.body),
              ),
              ConfidenceTag(level: confidence),
            ],
          ),
        ],
      ),
    );
  }
}

/// The scanned photo in the 120 px frame. A new scan shows the local file, a
/// saved scan loads its photo from storage.
class _ScanPhoto extends StatelessWidget {
  const _ScanPhoto({this.file, this.storagePath, required this.service});

  final File? file;
  final String? storagePath;
  final PlantScanService service;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => const Center(
          child: FIcon.named('image', size: 30, color: ScanColors.body),
        );

    Widget content;
    if (file != null) {
      content = Image.file(
        file!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    } else if (storagePath != null) {
      content = FutureBuilder<String>(
        future: service.signedPhotoUrl(storagePath!),
        builder: (context, snap) {
          if (!snap.hasData) return placeholder();
          return Image.network(
            snap.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => placeholder(),
          );
        },
      );
    } else {
      content = placeholder();
    }

    return Container(
      height: 120,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: content,
    );
  }
}
