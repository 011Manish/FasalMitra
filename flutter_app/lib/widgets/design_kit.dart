import 'package:flutter/material.dart';

import '../l10n/app_lang.dart';
import '../theme/app_theme.dart';
import 'figma_icons.dart';

/// Widest the content gets on tablets and the web, so layouts stay tidy.
const double kMaxContentWidth = 520;

/// Sage-green page background with the soft circle in the top-left corner.
class DesignBackground extends StatelessWidget {
  const DesignBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final d = (width > kMaxContentWidth ? kMaxContentWidth : width) * 1.15;
    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        children: [
          Positioned(
            left: -d * 0.28,
            top: -d * 0.3,
            width: d,
            height: d,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.circle,
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// The EN / नेपाली switch shown at the top of every screen in the design.
class LangToggle extends StatelessWidget {
  const LangToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLang.notifier,
      builder: (context, lang, _) {
        Widget segment(String code, String label) {
          final on = lang == code;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => AppLang.set(code),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: on ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [segment('en', 'EN'), segment('ne', 'नेपाली')],
          ),
        );
      },
    );
  }
}

/// White "< Back" pill from the design.
class BackPill extends StatelessWidget {
  const BackPill({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FIcon(Icons.chevron_left, size: 20),
              Text(
                tr('Back'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page layout for sign up, log in and similar forms: top bar, big title,
/// then the form. Scrolls on small screens and is centred on wide ones.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DesignBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (onBack != null) BackPill(onPressed: onBack!),
                        const Spacer(),
                        const LangToggle(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
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

/// Small bold label that sits above an input.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

/// Small grey helper text under an input.
class HelperText extends StatelessWidget {
  const HelperText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
      ),
    );
  }
}

/// Password input with the show/hide eye icon.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _hidden,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: '••••••••',
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Show password' : 'Hide password',
          icon: FIcon(
            _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}

/// A row of pill buttons where exactly one is selected (Nepal / India).
class PillChoice extends StatelessWidget {
  const PillChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  /// value -> label shown on the pill
  final Map<String, String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList();
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
              child: _Pill(
                label: entries[i].value,
                selected: entries[i].key == selected,
                onTap: enabled ? () => onChanged(entries[i].key) : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFA4C4A8) : AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

/// The two big "Farmer" / "Buyer" cards on the sign-up screen.
class RoleCards extends StatelessWidget {
  const RoleCards({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  /// 'farmer' or 'buyer' (the values the database accepts)
  final String selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget card(String value, IconData icon, String label) {
      final on = selected == value;
      return Expanded(
        child: Material(
          color: on ? const Color(0xFFA4C4A8) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: enabled ? () => onChanged(value) : null,
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: on ? AppColors.primary : AppColors.border,
                  width: on ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FIcon(
                    icon,
                    size: 34,
                    color: on ? AppColors.primary : Colors.black87,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: on ? AppColors.primary : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        card('farmer', Icons.agriculture, tr('Farmer')),
        const SizedBox(width: 12),
        card('buyer', Icons.shopping_basket_outlined, tr('Buyer')),
      ],
    );
  }
}

/// "✓ At least 8 characters" style line under the password field.
class CheckLine extends StatelessWidget {
  const CheckLine({super.key, required this.text, required this.ok});
  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          FIcon(
            ok ? Icons.check_circle : Icons.check_circle_outline,
            size: 16,
            color: ok ? AppColors.primary : AppColors.mutedText,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: ok ? AppColors.primary : AppColors.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
