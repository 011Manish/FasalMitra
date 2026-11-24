import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/profile_validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService(Supabase.instance.client);
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  UserProfile? _profile;
  bool _loadFailed = false;
  String? _country;
  String _language = 'en';
  String _role = 'farmer';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadFailed = false);
    try {
      final p = await _service.fetch();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _name.text = p.fullName ?? '';
        _phone.text = p.phone ?? '';
        _country = p.country;
        _language = p.preferredLanguage;
        _role = p.role;
      });
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final phone = _phone.text.trim();
    setState(() => _busy = true);
    try {
      await _service.save(UserProfile(
        fullName: _name.text.trim(),
        phone: phone.isEmpty ? null : phone,
        country: _country,
        preferredLanguage: _language,
        role: _role,
      ));
      _snack('Profile saved');
    } catch (_) {
      _snack('Could not save your profile. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------- UI: restyle freely, the logic above does not depend on it ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loadFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load your profile. Check your internet.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final profile = _profile;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            initialValue: _service.email ?? '',
            enabled: false,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Phone (optional, with country code)'),
            validator: (v) => optionalPhoneError(v ?? ''),
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Country',
            options: profileCountries,
            value: _country,
            onChanged: (v) => setState(() => _country = v),
            validator: (v) => v == null ? 'Select your country' : null,
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Preferred language',
            options: profileLanguages,
            value: _language,
            onChanged: (v) => setState(() => _language = v!),
          ),
          const SizedBox(height: 12),
          if (profile.isAdmin)
            const InputDecorator(
              decoration: InputDecoration(labelText: 'Role'),
              child: Text('Admin'),
            )
          else
            _dropdown(
              label: 'I am a',
              options: profileRoles,
              value: _role,
              onChanged: (v) => setState(() => _role = v!),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required Map<String, String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final e in options.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: _busy ? null : onChanged,
      validator: validator,
    );
  }
}
