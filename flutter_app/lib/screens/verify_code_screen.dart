import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_lang.dart';
import '../theme/app_theme.dart';
import '../widgets/design_kit.dart';
import '../widgets/figma_icons.dart';

enum VerifyMode { signUp, recovery }

/// "Verify your email" screen: the person types the 6-digit code that was
/// emailed to them. Only used when `AuthOptions.emailCodes` is true.
class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({
    super.key,
    required this.email,
    required this.mode,
    this.name,
  });

  final String email;
  final VerifyMode mode;
  final String? name;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  static const _resendSeconds = 30;

  final _ctrl = TextEditingController();
  Timer? _timer;
  int _wait = _resendSeconds;
  bool _busy = false;
  bool _done = false;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _wait = _resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_wait <= 1) {
        t.cancel();
        setState(() => _wait = 0);
      } else {
        setState(() => _wait--);
      }
    });
  }

  String get _masked {
    final parts = widget.email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return widget.email;
    final name = parts[0];
    final stars = '*' * (name.length > 1 ? name.length - 1 : 1);
    return '${name[0]}$stars@${parts[1]}';
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verify() async {
    final code = _ctrl.text.trim();
    if (code.length != 6) {
      _snack(tr('Code must be 6 digits'));
      return;
    }
    setState(() => _busy = true);
    try {
      await _auth.verifyOTP(
        type: widget.mode == VerifyMode.signUp
            ? OtpType.signup
            : OtpType.recovery,
        email: widget.email,
        token: code,
      );
      if (!mounted) return;
      if (widget.mode == VerifyMode.signUp) {
        setState(() => _done = true);
      } else {
        // The app then shows the "Set new password" screen by itself.
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(tr('Could not connect. Check your internet and try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      if (widget.mode == VerifyMode.signUp) {
        await _auth.resend(type: OtpType.signup, email: widget.email);
      } else {
        await _auth.resetPasswordForEmail(widget.email);
      }
      _snack(tr('A new code was sent to your email address.'));
      if (mounted) _startTimer();
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(tr('Could not connect. Check your internet and try again.'));
    }
  }

  Widget _codeBoxes() {
    final text = _ctrl.text;
    return Stack(
      children: [
        Row(
          children: [
            for (var i = 0; i < 6; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  child: AspectRatio(
                    aspectRatio: 0.85,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: i == text.length
                              ? AppColors.primary
                              : AppColors.border,
                          width: i == text.length ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        i < text.length ? text[i] : '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        // The real input sits invisibly on top, so tapping the boxes opens
        // the number keypad and pasting a code works.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context) {
        if (_done) {
          return AuthScaffold(
            title: tr('Account created'),
            subtitle: (widget.name == null || widget.name!.isEmpty)
                ? tr('Welcome')
                : '${tr('Welcome')}, ${widget.name!.split(' ').first}',
            children: [
              const SizedBox(height: 24),
              const FIcon(
                Icons.check_circle_outline,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(tr('Continue')),
              ),
            ],
          );
        }
        return AuthScaffold(
          title: tr('Verify your email'),
          subtitle: '${tr('We sent a 6-digit code to')} $_masked',
          onBack: () => Navigator.of(context).pop(),
          children: [
            FieldLabel(tr('Code')),
            _codeBoxes(),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: Text(tr('Verify')),
            ),
            const SizedBox(height: 12),
            Center(
              child: _wait > 0
                  ? Text(
                      '${tr('Resend code in')} $_wait s',
                      style: const TextStyle(color: AppColors.mutedText),
                    )
                  : TextButton(
                      onPressed: _resend,
                      child: Text(tr('Resend code')),
                    ),
            ),
          ],
        );
      },
    );
  }
}
