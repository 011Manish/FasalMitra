import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  final _phoneRe = RegExp(r'^\+?[0-9]{7,15}$');

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

  Future<void> _emailLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.length < 8) {
      _snack('Email + password (min 8 chars) required');
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      // Fall back to sign-up if the account doesn't exist yet.
      if (e.message.toLowerCase().contains('invalid')) {
        try {
          await Supabase.instance.client.auth.signUp(email: email, password: password);
          _snack('Account created. Check your email if confirmation is required.');
        } on AuthException catch (e2) {
          _snack(e2.message);
        }
      } else {
        _snack(e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text('Krishi', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              const Text('Sign in with your phone number to continue.'),
              const SizedBox(height: 24),
              if (!_useEmailFallback) ..._phoneFlow() else ..._emailFlow(),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : () => setState(() {
                  _useEmailFallback = !_useEmailFallback;
                  _codeSent = false;
                }),
                child: Text(_useEmailFallback ? 'Use phone number instead' : 'Use email + password instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _phoneFlow() => [
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone (with country code)'),
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

  List<Widget> _emailFlow() => [
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _emailLogin,
          child: const Text('Sign in / Sign up'),
        ),
      ];
}
