import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import '../l10n/app_lang.dart';
import '../widgets/scan_kit.dart';

/// Figma: "Camera Denied". Shown when the phone refuses camera access.
class PlantScanDeniedScreen extends StatelessWidget {
  const PlantScanDeniedScreen({super.key, required this.onUpload});

  /// Called after this screen closes, to open the gallery picker.
  final VoidCallback onUpload;

  Future<void> _openSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (_) {
      // Nothing else to do. The person can open Settings by hand.
    }
  }

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context) => ScanPage(
        topGap: 40,
        children: [
          const Center(child: ScanAlertBadge(iconName: 'camera')),
          const SizedBox(height: 12),
          Text(
            tr('Camera access is off'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: ScanColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          ScanSubtitle(
            tr('FasalMitra needs camera permission to scan your crops. Turn it on in your phone settings, or upload a photo instead.'),
            center: true,
          ),
          const SizedBox(height: 18),
          ScanPrimaryButton(
            label: tr('Open settings'),
            onPressed: _openSettings,
          ),
          const SizedBox(height: 10),
          ScanOutlineButton(
            label: tr('Upload from gallery'),
            iconName: 'upload',
            onPressed: () {
              Navigator.of(context).pop();
              onUpload();
            },
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text(
                tr('Back to home'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ScanColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
