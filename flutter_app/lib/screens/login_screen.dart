import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/auth_options.dart';
import '../l10n/app_lang.dart';
import '../services/profile_validators.dart';
import '../widgets/design_kit.dart';
import 'verify_code_screen.dart';

enum _EmailMode { signIn, signUp, forgot }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _busy = false;
  bool _codeSent = false;
  bool _useEmail = !AuthOptions.phoneLogin;
  _EmailMode _mode = _EmailMode.signIn;
  String _role = 'farmer'; // database accepts: farmer, buyer
  String _country = 'NP'; // database accepts: NP, IN

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  void dispose() {
    for (final c in [
      _phoneCtrl,
      _codeCtrl,
      _emailCtrl,
      _passwordCtrl,
      _confirmCtrl,
      _nameCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- Actions (same backend calls as before) ----------

  /// Runs [action] with the busy flag set and shows a plain message on failure.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(tr('Could not connect. Check your internet and try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Only NP and IN are valid in the database, so anything else returns null.
  String? _countryFromPhone(String phone) {
    if (phone.startsWith('+977')) return 'NP';
    if (phone.startsWith('+91')) return 'IN';
    return null;
  }

  void _sendOtp() {
    final phone = _phoneCtrl.text.trim();
    final error = phoneError(phone);
    if (error != null) {
      _snack(error);
      return;
    }
    _run(() async {
      final country = _countryFromPhone(phone);
      await _auth.signInWithOtp(
        phone: phone,
        data: {'phone': phone, if (country != null) 'country': country},
      );
      if (!mounted) return;
      setState(() => _codeSent = true);
      _snack(tr('Code sent. Check your SMS.'));
    });
  }

  void _verifyOtp() {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      _snack(tr('Code must be 6 digits'));
      return;
    }
    _run(
      () => _auth.verifyOTP(
        type: OtpType.sms,
        phone: _phoneCtrl.text.trim(),
        token: code,
      ),
    );
  }

  void _signIn() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _snack(tr('Enter your email and password'));
      return;
    }
    _run(() => _auth.signInWithPassword(email: email, password: password));
  }

  void _signUp() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final error =
        nameError(name) ?? emailError(email) ?? passwordError(password);
    if (error != null) {
      _snack(error);
      return;
    }
    if (password != _confirmCtrl.text) {
      _snack(tr('Passwords do not match'));
      return;
    }
    _run(() async {
      final res = await _auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'role': _role, 'country': _country},
      );
      if (res.session != null || !mounted) return;
      if (AuthOptions.emailCodes) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerifyCodeScreen(
              email: email,
              mode: VerifyMode.signUp,
              name: name,
            ),
          ),
        );
        return;
      }
      _snack(tr('Account created. Check your email to confirm, then log in.'));
      setState(() => _mode = _EmailMode.signIn);
    });
  }

  void _sendReset() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack(tr('Enter your email first'));
      return;
    }
    _run(() async {
      if (AuthOptions.emailCodes) {
        await _auth.resetPasswordForEmail(email);
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                VerifyCodeScreen(email: email, mode: VerifyMode.recovery),
          ),
        );
      } else {
        await _auth.resetPasswordForEmail(
          email,
          redirectTo: 'fasalmitra://login-callback/',
        );
        _snack(tr('Reset link sent. Open it on this phone.'));
      }
    });
  }

  void _setMode(_EmailMode mode) => setState(() => _mode = mode);

  void _toggleMethod() => setState(() {
    _useEmail = !_useEmail;
    _codeSent = false;
    _mode = _EmailMode.signIn;
  });

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context) {
        if (!_useEmail) {
          return AuthScaffold(
            title: tr('Welcome back'),
            subtitle: tr('Log in with your phone number.'),
            children: _phoneFlow(),
          );
        }
        return switch (_mode) {
          _EmailMode.signIn => AuthScaffold(
            title: tr('Welcome back'),
            subtitle: tr('Log in with your email address and password.'),
            children: _signInForm(),
          ),
          _EmailMode.signUp => AuthScaffold(
            title: tr('Create your account'),
            subtitle: tr('Join as a farmer or a buyer.'),
            children: _signUpForm(),
          ),
          _EmailMode.forgot => AuthScaffold(
            title: tr('Reset password'),
            subtitle: AuthOptions.emailCodes
                ? tr(
                    'Enter your email address. We will send you a 6-digit code.',
                  )
                : tr(
                    'Enter your email address. We will send you a reset link.',
                  ),
            onBack: () => _setMode(_EmailMode.signIn),
            children: _forgotForm(),
          ),
        };
      },
    );
  }

  Widget _emailField() => TextField(
    controller: _emailCtrl,
    enabled: !_busy,
    keyboardType: TextInputType.emailAddress,
    decoration: const InputDecoration(hintText: 'example@gmail.com'),
  );

  Widget _button(String label, VoidCallback onPressed) =>
      FilledButton(onPressed: _busy ? null : onPressed, child: Text(label));

  Widget _switchLine(String question, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(question),
          TextButton(
            onPressed: _busy ? null : onTap,
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 36),
            ),
            child: Text(
              action,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> get _countries => {'NP': tr('Nepal'), 'IN': tr('India')};

  List<Widget> _signInForm() => [
    FieldLabel(tr('Country')),
    PillChoice(
      options: _countries,
      selected: _country,
      enabled: !_busy,
      onChanged: (v) => setState(() => _country = v),
    ),
    FieldLabel(tr('Email')),
    _emailField(),
    FieldLabel(tr('Password')),
    PasswordField(controller: _passwordCtrl, enabled: !_busy),
    Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _busy ? null : () => _setMode(_EmailMode.forgot),
        style: TextButton.styleFrom(foregroundColor: Colors.black),
        child: Text(
          tr('Forgot password?'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ),
    const SizedBox(height: 8),
    _button(tr('Log in'), _signIn),
    _switchLine(
      tr('New to FasalMitra?'),
      tr('Create account'),
      () => _setMode(_EmailMode.signUp),
    ),
    if (AuthOptions.phoneLogin)
      TextButton(
        onPressed: _busy ? null : _toggleMethod,
        child: Text(tr('Use phone number instead')),
      ),
  ];

  List<Widget> _signUpForm() {
    final pw = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    return [
      RoleCards(
        selected: _role,
        enabled: !_busy,
        onChanged: (v) => setState(() => _role = v),
      ),
      FieldLabel(tr('Full name')),
      TextField(
        controller: _nameCtrl,
        enabled: !_busy,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: tr('Your full name')),
      ),
      FieldLabel(tr('Country')),
      PillChoice(
        options: _countries,
        selected: _country,
        enabled: !_busy,
        onChanged: (v) => setState(() => _country = v),
      ),
      FieldLabel(tr('Email')),
      _emailField(),
      HelperText(tr('Enter your existing gmail')),
      FieldLabel(tr('Password')),
      PasswordField(
        controller: _passwordCtrl,
        enabled: !_busy,
        onChanged: (_) => setState(() {}),
      ),
      CheckLine(text: tr('At least 8 characters'), ok: pw.length >= 8),
      CheckLine(
        text: tr('Both passwords match'),
        ok: pw.isNotEmpty && pw == confirm,
      ),
      FieldLabel(tr('Confirm password')),
      PasswordField(
        controller: _confirmCtrl,
        enabled: !_busy,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 20),
      _button(tr('Create account'), _signUp),
      _switchLine(
        tr('Already have an account?'),
        tr('Log in'),
        () => _setMode(_EmailMode.signIn),
      ),
    ];
  }

  List<Widget> _forgotForm() => [
    FieldLabel(tr('Email')),
    _emailField(),
    const SizedBox(height: 20),
    _button(
      AuthOptions.emailCodes ? tr('Send code') : tr('Send reset link'),
      _sendReset,
    ),
    const SizedBox(height: 4),
    TextButton(
      onPressed: _busy ? null : () => _setMode(_EmailMode.signIn),
      child: Text(tr('Back to log in')),
    ),
  ];

  List<Widget> _phoneFlow() => [
    FieldLabel(tr('Phone (with country code)')),
    TextField(
      controller: _phoneCtrl,
      enabled: !_busy && !_codeSent,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(hintText: '+97798XXXXXXXX'),
    ),
    if (_codeSent) ...[
      FieldLabel(tr('6-digit code')),
      TextField(
        controller: _codeCtrl,
        enabled: !_busy,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: const InputDecoration(counterText: ''),
      ),
    ],
    const SizedBox(height: 20),
    _button(
      _codeSent ? tr('Verify code') : tr('Send code'),
      _codeSent ? _verifyOtp : _sendOtp,
    ),
    if (_codeSent)
      TextButton(
        onPressed: () => setState(() => _codeSent = false),
        child: Text(tr('Use a different number')),
      ),
    if (AuthOptions.phoneLogin)
      TextButton(
        onPressed: _busy ? null : _toggleMethod,
        child: Text(tr('Use email and password instead')),
      ),
  ];
}
