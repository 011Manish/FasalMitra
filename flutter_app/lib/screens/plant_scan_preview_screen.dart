import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_lang.dart';
import '../theme/app_theme.dart';
import '../widgets/figma_icons.dart';
import '../widgets/scan_kit.dart';
import 'plant_scan_result_screen.dart';

/// Figma: "Photo Preview". Shows the chosen photo before it is analyzed.
class PlantScanPreviewScreen extends StatelessWidget {
  const PlantScanPreviewScreen({
    super.key,
    required this.file,
    required this.source,
    required this.onRetake,
    this.farmId,
  });

  final File file;

  /// Where the photo came from, so "Retake" opens the same picker again.
  final ImageSource source;
  final ValueChanged<ImageSource> onRetake;
  final String? farmId;

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context) => ScanPage(
        children: [
          ScanTitle(tr('Check your photo')),
          const SizedBox(height: 4),
          ScanSubtitle(tr('Make sure the leaf is sharp and fills the frame.')),
          const SizedBox(height: 12),
          Container(
            height: 340,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.mutedText, width: 2),
            ),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: FIcon.named('image', size: 44, color: ScanColors.body),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ScanPrimaryButton(
            label: tr('Analyze photo'),
            iconName: 'scan',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => PlantScanResultScreen.newScan(
                    file: file,
                    farmId: farmId,
                    source: source,
                    onRetake: onRetake,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          ScanOutlineButton(
            label: tr('Retake'),
            onPressed: () {
              Navigator.of(context).pop();
              onRetake(source);
            },
          ),
        ],
      ),
    );
  }
}
