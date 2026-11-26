import 'package:flutter/material.dart';

part 'figma_icons_data.dart';

/// One icon from the Figma design: the size of its square and its outlines.
class FigmaIconData {
  const FigmaIconData(this.size, this.paths);
  final double size;
  final List<String> paths;
}

final Map<String, Path> _pathCache = {};

Path _buildPath(String name) {
  return _pathCache.putIfAbsent(name, () {
    final data = kFigmaIcons[name]!;
    final path = Path()..fillType = PathFillType.nonZero;
    for (final d in data.paths) {
      final t = d.split(RegExp(r'\s+'));
      var i = 0;
      double n() => double.parse(t[i++]);
      while (i < t.length) {
        final token = t[i++];
        // A command letter can be glued to its first number ("M22").
        final cmd = token[0];
        if (token.length > 1) {
          t.insert(i, token.substring(1));
        }
        switch (cmd) {
          case 'M':
            path.moveTo(n(), n());
          case 'L':
            path.lineTo(n(), n());
          case 'C':
            path.cubicTo(n(), n(), n(), n(), n(), n());
          case 'Z':
            path.close();
        }
      }
    }
    return path;
  });
}

class _FigmaIconPainter extends CustomPainter {
  _FigmaIconPainter(this.name, this.color);
  final String name;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final data = kFigmaIcons[name]!;
    final s = size.width / data.size;
    canvas.scale(s, s);
    canvas.drawPath(
      _buildPath(name),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_FigmaIconPainter old) =>
      old.name != name || old.color != color;
}

/// Material icon code point -> icon name in the Figma file.
/// Anything not listed here keeps its normal Material icon.
final Map<int, String> _materialToFigma = {
  Icons.home.codePoint: 'home',
  Icons.home_outlined.codePoint: 'home',
  Icons.grass.codePoint: 'sprout',
  Icons.eco_outlined.codePoint: 'sprout',
  Icons.local_florist_outlined.codePoint: 'sprout',
  Icons.agriculture.codePoint: 'farmer',
  Icons.shopping_basket_outlined.codePoint: 'buyer',
  Icons.agriculture_outlined.codePoint: 'sprout',
  Icons.trending_up.codePoint: 'trend',
  Icons.trending_up_outlined.codePoint: 'trend',
  Icons.person.codePoint: 'user',
  Icons.person_outline.codePoint: 'user',
  Icons.inventory_2_outlined.codePoint: 'pkg',
  Icons.shopping_bag_outlined.codePoint: 'bag',
  Icons.menu_book_outlined.codePoint: 'book',
  Icons.import_contacts_outlined.codePoint: 'book',
  Icons.center_focus_strong_outlined.codePoint: 'scan',
  Icons.notifications_outlined.codePoint: 'bell',
  Icons.notifications_none.codePoint: 'bell',
  Icons.notifications_active.codePoint: 'bell',
  Icons.chevron_right.codePoint: 'chevR',
  Icons.chevron_left.codePoint: 'back',
  Icons.search.codePoint: 'search',
  Icons.edit_outlined.codePoint: 'edit',
  Icons.delete_outline.codePoint: 'trash',
  Icons.add.codePoint: 'plus',
  Icons.close.codePoint: 'x',
  Icons.clear.codePoint: 'x',
  Icons.check_circle.codePoint: 'check',
  Icons.check_circle_outline.codePoint: 'check',
  Icons.photo_camera_outlined.codePoint: 'camera',
  Icons.add_a_photo_outlined.codePoint: 'camera',
  Icons.photo_library_outlined.codePoint: 'image',
  Icons.image_outlined.codePoint: 'image',
  Icons.phone_outlined.codePoint: 'phone',
  Icons.call_outlined.codePoint: 'phone',
  Icons.mail_outline.codePoint: 'mail',
  Icons.email_outlined.codePoint: 'mail',
  Icons.visibility_outlined.codePoint: 'eye',
  Icons.visibility_off_outlined.codePoint: 'eyeoff',
  Icons.play_circle_outline.codePoint: 'play',
  Icons.ondemand_video_outlined.codePoint: 'play',
  Icons.help_outline.codePoint: 'help',
  Icons.history.codePoint: 'clock',
};

/// Drop-in replacement for [Icon]. Draws the icon from the Figma design when
/// there is one for it, otherwise falls back to the normal Material icon.
/// Use `FIcon.named('sprout')` to ask for a Figma icon directly.
class FIcon extends StatelessWidget {
  const FIcon(this.icon, {super.key, this.size, this.color, this.semanticLabel})
      : name = null;

  const FIcon.named(this.name,
      {super.key, this.size, this.color, this.semanticLabel})
      : icon = null;

  final IconData? icon;
  final String? name;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final figmaName =
        name ?? (icon == null ? null : _materialToFigma[icon!.codePoint]);
    if (figmaName == null || !kFigmaIcons.containsKey(figmaName)) {
      return Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
    }
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? 24.0;
    var c = color ?? theme.color ?? const Color(0xFF000000);
    final opacity = theme.opacity;
    if (opacity != null && opacity < 1) c = c.withOpacity(c.opacity * opacity);
    Widget w = SizedBox(
      width: s,
      height: s,
      child: CustomPaint(painter: _FigmaIconPainter(figmaName, c)),
    );
    if (semanticLabel != null) {
      w = Semantics(label: semanticLabel, image: true, child: w);
    } else {
      w = ExcludeSemantics(child: w);
    }
    return w;
  }
}
