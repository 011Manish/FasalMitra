import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ResetPasswordScreen({super.key, required this.onDone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _pwCtrl = TextEditingController();
  bool _busy = false;

  Future<void> _save() async {
    if (_pwCtrl.text.length < 8) {
      _snack('Password must be at least 8 characters');
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: _pwCtrl.text));
      _snack('Password updated.');
      widget.onDone();
    } on AuthException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  void dispose() {
    _pwCtrl.dispose();
    super.dispose();
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
              Text('Set new password',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              TextField(
                controller: _pwCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'New password (min 8 characters)'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Save password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
