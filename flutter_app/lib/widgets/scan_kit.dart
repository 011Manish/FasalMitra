import 'package:flutter/material.dart';

import '../l10n/app_lang.dart';
import '../theme/app_theme.dart';
import 'design_kit.dart';
import 'figma_icons.dart';

/// Colors used only by the AI Scan screens (taken from the Figma file).
abstract final class ScanColors {
  static const dark = Color(0xFF111611); // Scan Camera page
  static const darkPanel = Color(0xFF1E2A20); // camera view box
  static const tipCheck = Color(0xFF9FD3A6);
  static const ink = Color(0xFF000000);
  static const body = Color(0xFF4A4E4A);
  static const greenDark = Color(0xFF2F6636);
  static const warnBg = Color(0xFFF2DFAE);
  static const warnText = Color(0xFF6B4600);
  static const errBg = Color(0xFFF3CFCC);
  static const errText = Color(0xFF8C1D18);
  static const errIcon = Color(0xFFB3261E);
  static const card = Color(0x9EFFFFFF); // white @ 62%
}

/// Light page used by every scan screen except the camera: sage background,
/// "< Back" pill and the EN / नेपाली switch on top, then the content.
class ScanPage extends StatelessWidget {
  const ScanPage({
    super.key,
    required this.children,
    this.onBack,
    this.showBack = true,
    this.topGap = 14,
  });

  final List<Widget> children;
  final VoidCallback? onBack;
  final bool showBack;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    return DesignBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (showBack)
                          BackPill(
                            onPressed:
                                onBack ?? () => Navigator.of(context).maybePop(),
                          ),
                        const Spacer(),
                        const LangToggle(),
                      ],
                    ),
                    SizedBox(height: topGap),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Big page title, 27 px semi-bold as in the design.
class ScanTitle extends StatelessWidget {
  const ScanTitle(this.text, {super.key, this.size = 27});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: ScanColors.ink,
        height: 1.2,
      ),
    );
  }
}

/// Grey body line under a title.
class ScanSubtitle extends StatelessWidget {
  const ScanSubtitle(this.text, {super.key, this.center = false});
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: const TextStyle(
        fontSize: 14,
        color: ScanColors.body,
        height: 1.4,
      ),
    );
  }
}

/// Green filled pill button (48 px high) with an optional icon.
class ScanPrimaryButton extends StatelessWidget {
  const ScanPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconName,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? iconName;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: onPressed == null
            ? AppColors.primary.withValues(alpha: 0.5)
            : AppColors.primary,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : _ButtonRow(
                    label: label,
                    color: Colors.white,
                    icon: icon,
                    iconName: iconName,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Pill button with a 2 px outline. [onDark] gives the white version used on
/// the camera page, otherwise it is the green outline used everywhere else.
class ScanOutlineButton extends StatelessWidget {
  const ScanOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconName,
    this.onDark = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? iconName;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : ScanColors.ink;
    final border = onDark ? Colors.white : AppColors.primary;
    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: border, width: 2)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Center(
            child: _ButtonRow(
              label: label,
              color: fg,
              icon: icon,
              iconName: iconName,
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonRow extends StatelessWidget {
  const _ButtonRow({
    required this.label,
    required this.color,
    this.icon,
    this.iconName,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final String? iconName;

  @override
  Widget build(BuildContext context) {
    Widget? leading;
    if (iconName != null) {
      leading = FIcon.named(iconName, size: 20, color: color);
    } else if (icon != null) {
      leading = FIcon(icon, size: 20, color: color);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Translucent white rounded card with an optional bold heading.
class ScanCard extends StatelessWidget {
  const ScanCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: ScanColors.card,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// "What we found" style card: bold heading, body text in dark green.
class ScanInfoCard extends StatelessWidget {
  const ScanInfoCard({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ScanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ScanColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ScanColors.greenDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Same card, but with a bulleted list.
class ScanListCard extends StatelessWidget {
  const ScanListCard({super.key, required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return ScanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ScanColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ',
                      style: TextStyle(color: ScanColors.greenDark)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ScanColors.greenDark,
                        height: 1.4,
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

enum ScanBannerKind { warning, error }

/// Amber (warning) or red (error) message bar, with an optional action.
class ScanBanner extends StatelessWidget {
  const ScanBanner({
    super.key,
    required this.text,
    this.kind = ScanBannerKind.warning,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final ScanBannerKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isError = kind == ScanBannerKind.error;
    final bg = isError ? ScanColors.errBg : ScanColors.warnBg;
    final fg = isError ? ScanColors.errText : ScanColors.warnText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: fg,
                height: 1.35,
              ),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: fg,
                side: BorderSide(color: fg, width: 1.5),
                minimumSize: const Size(0, 29),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: const StadiumBorder(),
              ),
              child: Text(
                actionLabel!,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small rounded label such as "High confidence".
class ConfidenceTag extends StatelessWidget {
  const ConfidenceTag({super.key, required this.level});

  /// 'high', 'medium' or 'low'
  final String level;

  static String label(String level) {
    switch (level) {
      case 'high':
        return tr('High confidence');
      case 'medium':
        return tr('Medium confidence');
      default:
        return tr('Low confidence');
    }
  }

  @override
  Widget build(BuildContext context) {
    final low = level != 'high' && level != 'medium';
    final bg = low
        ? ScanColors.warnBg
        : AppColors.primary.withValues(alpha: 0.2);
    final fg = low ? ScanColors.warnText : ScanColors.greenDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label(level),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

/// Round icon badge used on the "Camera access is off" and "Scan failed"
/// screens (96 px pink circle with a red icon).
class ScanAlertBadge extends StatelessWidget {
  const ScanAlertBadge({super.key, required this.iconName});
  final String iconName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        color: ScanColors.errBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: FIcon.named(iconName, size: 44, color: ScanColors.errIcon),
    );
  }
}
