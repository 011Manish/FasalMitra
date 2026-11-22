import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _EmailMode { signIn, signUp, forgot }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static final _phoneRe = RegExp(r'^\+?[0-9]{7,15}$');
  static const _phoneHint = 'Enter a valid phone number, e.g. +9779812345678';
  static const _gap = SizedBox(height: 12);

  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _signUpPhoneCtrl = TextEditingController();

  bool _busy = false;
  bool _codeSent = false;
  bool _useEmail = false;
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
      _signUpPhoneCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- Actions ----------

  /// Runs [action] with the busy flag set and shows any auth error.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AuthException catch (e) {
      _snack(e.message);
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
    if (!_phoneRe.hasMatch(phone)) {
      _snack(_phoneHint);
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
      _snack('Code sent. Check your SMS.');
    });
  }

  void _verifyOtp() {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      _snack('Code must be 6 digits');
      return;
    }
    _run(() => _auth.verifyOTP(
          type: OtpType.sms,
          phone: _phoneCtrl.text.trim(),
          token: code,
        ));
  }

  void _signIn() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _snack('Enter your email and password');
      return;
    }
    _run(() => _auth.signInWithPassword(email: email, password: password));
  }

  void _signUp() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final phone = _signUpPhoneCtrl.text.trim();
    if (email.isEmpty || password.length < 8) {
      _snack('Email + password (min 8 chars) required');
      return;
    }
    if (phone.isNotEmpty && !_phoneRe.hasMatch(phone)) {
      _snack(_phoneHint);
      return;
    }
    _run(() async {
      final res = await _auth.signUp(
        email: email,
        password: password,
        data: {
          'role': _role,
          'country': _country,
          if (phone.isNotEmpty) 'phone': phone,
        },
      );
      if (res.session != null || !mounted) return;
      _snack('Account created. Check your email to confirm, then sign in.');
      setState(() => _mode = _EmailMode.signIn);
    });
  }

  void _sendResetLink() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Enter your email first');
      return;
    }
    _run(() async {
      await _auth.resetPasswordForEmail(
        email,
        redirectTo: 'fasalmitra://login-callback/',
      );
      _snack('Reset link sent. Open it on this phone.');
    });
  }

  void _setMode(_EmailMode mode) => setState(() => _mode = mode);

  void _toggleMethod() => setState(() {
        _useEmail = !_useEmail;
        _codeSent = false;
        _mode = _EmailMode.signIn;
      });

  // ---------- UI ----------

  String get _subtitle => !_useEmail
      ? 'Sign in with your phone number to continue.'
      : switch (_mode) {
          _EmailMode.signIn => 'Sign in with your email and password.',
          _EmailMode.signUp => 'Create a new account.',
          _EmailMode.forgot =>
            'Enter your email and we will send you a reset link.',
        };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text('FASALMITRA',
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(_subtitle),
              const SizedBox(height: 24),
              ..._useEmail ? _emailFlow() : _phoneFlow(),
              _gap,
              _link(
                _useEmail
                    ? 'Use phone number instead'
                    : 'Use email + password instead',
                _toggleMethod,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    bool obscure = false,
    bool enabled = true,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      enabled: enabled,
      maxLength: maxLength,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _button(String label, VoidCallback onPressed) =>
      FilledButton(onPressed: _busy ? null : onPressed, child: Text(label));

  Widget _outlined(String label, VoidCallback onPressed) =>
      OutlinedButton(onPressed: _busy ? null : onPressed, child: Text(label));

  Widget _link(String label, VoidCallback onPressed) =>
      TextButton(onPressed: _busy ? null : onPressed, child: Text(label));

  Widget _choice(
    String label,
    Map<String, String> options,
    String selected,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: [
            for (final e in options.entries)
              ButtonSegment(value: e.key, label: Text(e.value)),
          ],
          selected: {selected},
          onSelectionChanged: _busy ? null : (s) => onChanged(s.first),
        ),
      ],
    );
  }

  List<Widget> _phoneFlow() => [
        _field(_phoneCtrl, 'Phone (with country code)',
            keyboard: TextInputType.phone, enabled: !_codeSent),
        _gap,
        if (_codeSent)
          _field(_codeCtrl, '6-digit code',
              keyboard: TextInputType.number, maxLength: 6),
        _gap,
        _button(
          _codeSent ? 'Verify code' : 'Send code',
          _codeSent ? _verifyOtp : _sendOtp,
        ),
        if (_codeSent)
          _link('Use a different number',
              () => setState(() => _codeSent = false)),
      ];

  List<Widget> _emailFlow() {
    final email =
        _field(_emailCtrl, 'Email', keyboard: TextInputType.emailAddress);
    return switch (_mode) {
      _EmailMode.signIn => [
          email,
          _gap,
          _field(_passwordCtrl, 'Password', obscure: true),
          const SizedBox(height: 16),
          _button('Sign in', _signIn),
          const SizedBox(height: 8),
          _outlined('Create account', () => _setMode(_EmailMode.signUp)),
          _link('Forgot password?', () => _setMode(_EmailMode.forgot)),
        ],
      _EmailMode.signUp => [
          email,
          _gap,
          _field(_passwordCtrl, 'Password (min 8 characters)', obscure: true),
          _gap,
          _field(_signUpPhoneCtrl, 'Phone (optional, with country code)',
              keyboard: TextInputType.phone),
          const SizedBox(height: 16),
          _choice('I am a', const {'farmer': 'Farmer', 'buyer': 'Buyer'}, _role,
              (v) => setState(() => _role = v)),
          const SizedBox(height: 16),
          _choice('Country', const {'NP': 'Nepal', 'IN': 'India'}, _country,
              (v) => setState(() => _country = v)),
          const SizedBox(height: 16),
          _button('Create account', _signUp),
          _link('I already have an account', () => _setMode(_EmailMode.signIn)),
        ],
      _EmailMode.forgot => [
          email,
          const SizedBox(height: 16),
          _button('Send reset link', _sendResetLink),
          _link('Back to sign in', () => _setMode(_EmailMode.signIn)),
        ],
    };
  }
}
