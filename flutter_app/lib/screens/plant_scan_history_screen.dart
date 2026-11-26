import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_lang.dart';
import '../models/farm_profile.dart';
import '../models/plant_scan.dart';
import '../models/scan_summary.dart';
import '../services/farm_service.dart';
import '../services/plant_scan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/figma_icons.dart';
import '../widgets/scan_kit.dart';
import 'camera_choice_screen.dart';
import 'plant_scan_result_screen.dart';

class _HistoryData {
  const _HistoryData(this.scans, this.farmNames);
  final List<PlantScan> scans;
  final Map<String, String> farmNames;
}

/// Figma: "Scan History" and "Scan History Empty".
class PlantScanHistoryScreen extends StatefulWidget {
  const PlantScanHistoryScreen({super.key, required this.service});
  final PlantScanService service;

  @override
  State<PlantScanHistoryScreen> createState() => _PlantScanHistoryScreenState();
}

class _PlantScanHistoryScreenState extends State<PlantScanHistoryScreen> {
  late Future<_HistoryData> _future = _load();

  Future<_HistoryData> _load() async {
    final scans = await widget.service.listMine();
    // Farm names are a nice extra. If they cannot load, the list still works.
    var names = <String, String>{};
    try {
      final farms =
          await FarmService(Supabase.instance.client).listMine();
      names = {for (final FarmProfile f in farms) f.id: f.name};
    } catch (_) {}
    return _HistoryData(scans, names);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context) => ScanPage(
        children: [
          ScanTitle(tr('Scan history')),
          const SizedBox(height: 14),
          FutureBuilder<_HistoryData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: ScanColors.greenDark),
                  ),
                );
              }
              if (snapshot.hasError) {
                return _MessageCard(
                  title: tr('Could not load history'),
                  body: tr('Could not load history. Check your internet.'),
                  buttonLabel: tr('Retry'),
                  onPressed: _reload,
                );
              }
              final data = snapshot.data!;
              if (data.scans.isEmpty) {
                return _MessageCard(
                  iconName: 'scan',
                  title: tr('No scans yet'),
                  body: tr('Scan a crop and its result will appear here.'),
                  buttonLabel: tr('Scan a crop'),
                  buttonIcon: 'camera',
                  onPressed: () => popToScanCamera(context),
                );
              }
              return Column(
                children: [
                  for (final scan in data.scans)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ScanRow(
                        scan: scan,
                        service: widget.service,
                        farmName:
                            scan.farmId == null ? null : data.farmNames[scan.farmId],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One saved scan: photo, issue, farm and date, confidence tag.
class _ScanRow extends StatelessWidget {
  const _ScanRow({
    required this.scan,
    required this.service,
    required this.farmName,
  });

  final PlantScan scan;
  final PlantScanService service;
  final String? farmName;

  @override
  Widget build(BuildContext context) {
    final summary = ScanSummary.fromScan(scan);
    final date = DateFormat('d MMM yyyy').format(scan.createdAt.toLocal());
    final line = farmName == null ? date : '$farmName · $date';
    return Material(
      color: ScanColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlantScanResultScreen.existing(scan: scan),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _Thumb(path: scan.photoStoragePath, service: service),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.issue,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ScanColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ScanColors.greenDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ConfidenceTag(level: summary.confidence),
                  ],
                ),
              ),
              const FIcon.named('chevR', size: 18, color: ScanColors.body),
            ],
          ),
        ),
      ),
    );
  }
}

/// 56 px photo square. Falls back to the image icon while loading or when the
/// photo cannot be opened.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.service});
  final String path;
  final PlantScanService service;

  @override
  Widget build(BuildContext context) {
    Widget icon() => const Center(
          child: FIcon.named('image', size: 22, color: ScanColors.greenDark),
        );
    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: FutureBuilder<String>(
        future: service.signedPhotoUrl(path),
        builder: (context, snap) {
          if (!snap.hasData) return icon();
          return Image.network(
            snap.data!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => icon(),
          );
        },
      ),
    );
  }
}

/// Empty / error card with one button.
class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
    this.iconName,
    this.buttonIcon,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;
  final String? iconName;
  final String? buttonIcon;

  @override
  Widget build(BuildContext context) {
    return ScanCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          if (iconName != null) ...[
            FIcon.named(iconName, size: 44, color: ScanColors.body),
            const SizedBox(height: 10),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: ScanColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          ScanSubtitle(body, center: true),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: Material(
              color: AppColors.primary,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (buttonIcon != null) ...[
                        FIcon.named(buttonIcon, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
