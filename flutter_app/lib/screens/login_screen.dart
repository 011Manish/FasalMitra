import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  bool _codeSent = false;
  bool _busy = false;
  bool _useEmailFallback = false;
  _EmailMode _mode = _EmailMode.signIn;

  final _phoneRe = RegExp(r'^\+?[0-9]{7,15}$');

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ---------- Phone ----------

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (!_phoneRe.hasMatch(phone)) {
      _snack('Enter a valid phone number, e.g. +9779812345678');
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _snack('Code sent. Check your SMS.');
    } on AuthException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      _snack('Code must be 6 digits');
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: code,
      );
    } on AuthException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- Email ----------

  Future<void> _emailSignIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _snack('Enter your email and password');
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emailSignUp() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.length < 8) {
      _snack('Email + password (min 8 chars) required');
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await Supabase.instance.client.auth
          .signUp(email: email, password: password);
      if (!mounted) return;
      if (res.session == null) {
        _snack('Account created. Check your email to confirm, then sign in.');
        setState(() => _mode = _EmailMode.signIn);
      }
    } on AuthException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendResetLink() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Enter your email first');
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'fasalmitra://login-callback/',
      );
      _snack('Reset link sent. Open it on this phone.');
    } on AuthException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setMode(_EmailMode m) => setState(() => _mode = m);

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- UI ----------

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
              Text(_subtitle()),
              const SizedBox(height: 24),
              if (!_useEmailFallback) ..._phoneFlow() else ..._emailFlow(),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _useEmailFallback = !_useEmailFallback;
                          _codeSent = false;
                          _mode = _EmailMode.signIn;
                        }),
                child: Text(_useEmailFallback
                    ? 'Use phone number instead'
                    : 'Use email + password instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    if (!_useEmailFallback) return 'Sign in with your phone number to continue.';
    switch (_mode) {
      case _EmailMode.signIn:
        return 'Sign in with your email and password.';
      case _EmailMode.signUp:
        return 'Create a new account.';
      case _EmailMode.forgot:
        return 'Enter your email and we will send you a reset link.';
    }
  }

  List<Widget> _phoneFlow() => [
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration:
              const InputDecoration(labelText: 'Phone (with country code)'),
          enabled: !_codeSent,
        ),
        const SizedBox(height: 12),
        if (_codeSent)
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: '6-digit code'),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : (_codeSent ? _verifyOtp : _sendOtp),
          child: Text(_codeSent ? 'Verify code' : 'Send code'),
        ),
        if (_codeSent)
          TextButton(
            onPressed: _busy ? null : () => setState(() => _codeSent = false),
            child: const Text('Use a different number'),
          ),
      ];

  List<Widget> _emailFlow() {
    final emailField = TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'Email'),
    );

    switch (_mode) {
      case _EmailMode.signIn:
        return [
          emailField,
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _emailSignIn,
            child: const Text('Sign in'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : () => _setMode(_EmailMode.signUp),
            child: const Text('Create account'),
          ),
          TextButton(
            onPressed: _busy ? null : () => _setMode(_EmailMode.forgot),
            child: const Text('Forgot password?'),
          ),
        ];

      case _EmailMode.signUp:
        return [
          emailField,
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration:
                const InputDecoration(labelText: 'Password (min 8 characters)'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _emailSignUp,
            child: const Text('Create account'),
          ),
          TextButton(
            onPressed: _busy ? null : () => _setMode(_EmailMode.signIn),
            child: const Text('I already have an account'),
          ),
        ];

      case _EmailMode.forgot:
        return [
          emailField,
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _sendResetLink,
            child: const Text('Send reset link'),
          ),
          TextButton(
            onPressed: _busy ? null : () => _setMode(_EmailMode.signIn),
            child: const Text('Back to sign in'),
          ),
        ];
    }
  }
}