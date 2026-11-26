import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_lang.dart';
import '../services/photo_service.dart';
import '../services/plant_scan_service.dart';
import '../widgets/figma_icons.dart';
import '../widgets/scan_kit.dart';
import 'plant_scan_denied_screen.dart';
import 'plant_scan_history_screen.dart';
import 'plant_scan_preview_screen.dart';
import 'support_screen.dart';

/// Name of the AI Scan start page in the navigator. The result screens use it
/// to return here ("Scan another crop").
const String kScanCameraRoute = 'scan_camera';

/// Goes back to the AI Scan start page. If it is not open, stops at Home.
void popToScanCamera(BuildContext context) {
  var found = false;
  Navigator.of(context).popUntil((route) {
    if (route.settings.name == kScanCameraRoute) found = true;
    return found || route.isFirst;
  });
}

/// AI Scan start page (Figma: "Scan Camera"). Take a photo or upload one from
/// the gallery, then check it, analyze it and see the result.
class CameraChoiceScreen extends StatefulWidget {
  const CameraChoiceScreen({super.key, this.farmId});

  /// Optional: attach the scan to this farm.
  final String? farmId;

  static Route<void> route({String? farmId}) => MaterialPageRoute<void>(
        settings: const RouteSettings(name: kScanCameraRoute),
        builder: (_) => CameraChoiceScreen(farmId: farmId),
      );

  @override
  State<CameraChoiceScreen> createState() => _CameraChoiceScreenState();
}

class _CameraChoiceScreenState extends State<CameraChoiceScreen> {
  late final _scans = PlantScanService(Supabase.instance.client);
  final _picker = ImagePicker();

  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlantScanDeniedScreen(
              onUpload: () => _pick(ImageSource.gallery),
            ),
          ),
        );
      } else {
        _snack(tr('Could not open the camera. Try uploading a photo instead.'));
      }
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(tr('Could not open the camera. Try uploading a photo instead.'));
      return;
    }

    if (!mounted) return;
    setState(() => _busy = false);
    if (picked == null) return; // the user closed the picker

    final file = File(picked.path);
    try {
      if (await file.length() > maxPhotoBytes) {
        _snack(tr('This photo is too large. Use a photo under 5 MB.'));
        return;
      }
    } catch (_) {
      _snack(tr('Could not read this photo. Please try another one.'));
      return;
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlantScanPreviewScreen(
          file: file,
          source: source,
          farmId: widget.farmId,
          onRetake: _pick,
        ),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlantScanHistoryScreen(service: _scans),
      ),
    );
  }

  void _openHelp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: ScanColors.dark,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _DarkPill(
                            onTap: () => Navigator.of(context).maybePop(),
                            leading: const FIcon(Icons.chevron_left,
                                size: 20, color: Colors.white),
                            label: tr('Back'),
                            fontSize: 14,
                            padding:
                                const EdgeInsets.fromLTRB(8, 8, 14, 8),
                          ),
                          const Spacer(),
                          _DarkPill(
                            onTap: _openHistory,
                            leading: const FIcon(Icons.history,
                                size: 16, color: Colors.white),
                            label: tr('History'),
                            fontSize: 13,
                            padding:
                                const EdgeInsets.fromLTRB(12, 9, 12, 9),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('Scan your crop'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CameraView(label: tr('Camera view')),
                      const SizedBox(height: 12),
                      const _PhotoTips(),
                      const SizedBox(height: 14),
                      ScanPrimaryButton(
                        label: tr('Take photo'),
                        iconName: 'camera',
                        busy: _busy,
                        onPressed:
                            _busy ? null : () => _pick(ImageSource.camera),
                      ),
                      const SizedBox(height: 10),
                      ScanOutlineButton(
                        label: tr('Upload from gallery'),
                        iconName: 'upload',
                        onDark: true,
                        onPressed:
                            _busy ? null : () => _pick(ImageSource.gallery),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openHelp,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            tr('Camera not working? See camera help'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Translucent white pill used for "Back" and "History" on the dark page.
class _DarkPill extends StatelessWidget {
  const _DarkPill({
    required this.onTap,
    required this.leading,
    required this.label,
    required this.fontSize,
    required this.padding,
  });

  final VoidCallback onTap;
  final Widget leading;
  final String label;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The viewfinder box. The real camera opens when "Take photo" is pressed.
class _CameraView extends StatelessWidget {
  const _CameraView({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      decoration: BoxDecoration(
        color: ScanColors.darkPanel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FIcon.named('camera', size: 44, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTips extends StatelessWidget {
  const _PhotoTips();

  @override
  Widget build(BuildContext context) {
    final tips = [
      tr('Fill the frame with one leaf.'),
      tr('Use daylight and avoid shadows.'),
      tr('Hold the camera steady until it is sharp.'),
      tr('Include both healthy and affected parts.'),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Photo tips'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: FIcon.named('check',
                        size: 16, color: ScanColors.tipCheck),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
