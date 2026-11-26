import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_lang.dart';
import '../models/user_profile.dart';
import '../services/farm_service.dart';
import '../services/marketplace_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design_kit.dart';
import 'my_listings_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'support_screen.dart';
import '../widgets/figma_icons.dart';

/// The Profile tab: who you are, shortcuts, and log out.
class ProfileHubScreen extends StatefulWidget {
  const ProfileHubScreen({
    super.key,
    required this.farms,
    required this.marketplace,
  });

  final FarmService farms;
  final MarketplaceService marketplace;

  @override
  State<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

class _ProfileHubScreenState extends State<ProfileHubScreen> {
  late final _service = ProfileService(Supabase.instance.client);
  late Future<UserProfile> _profile = _service.fetch();

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _editProfile() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    if (mounted) setState(() => _profile = _service.fetch());
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Delete account?')),
        content: Text(
          tr(
            'This will permanently delete your account and all your farm profiles. This cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.farms.deleteAccount();
    }
  }

  String _roleLabel(String role) => switch (role) {
    'farmer' => tr('Farmer'),
    'buyer' => tr('Buyer'),
    'admin' => 'Admin',
    _ => role,
  };

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context) {
        final email = _service.email ?? '';
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              tr('Profile'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: const [LangToggle(), SizedBox(width: 12)],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: FIcon(
                              Icons.person_outline,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: FutureBuilder<UserProfile>(
                              future: _profile,
                              builder: (context, snap) {
                                final p = snap.data;
                                final name =
                                    (p?.fullName?.trim().isNotEmpty ?? false)
                                    ? p!.fullName!.trim()
                                    : email;
                                final detail = p == null
                                    ? email
                                    : '$email · ${_roleLabel(p.role)}';
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      detail,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                    if (snap.hasError)
                                      Text(
                                        tr(
                                          'Could not load your profile. Check your internet.',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.edit_outlined,
                          label: tr('Edit profile'),
                          onTap: _editProfile,
                        ),
                        const Divider(height: 1),
                        _MenuTile(
                          icon: Icons.inventory_2_outlined,
                          label: tr('My listings'),
                          onTap: () => _open(
                            MyListingsScreen(service: widget.marketplace),
                          ),
                        ),
                        const Divider(height: 1),
                        _MenuTile(
                          icon: Icons.notifications_outlined,
                          label: tr('Notifications'),
                          onTap: () => _open(const NotificationsScreen()),
                        ),
                        const Divider(height: 1),
                        _MenuTile(
                          icon: Icons.help_outline,
                          label: tr('Support'),
                          onTap: () => _open(const SupportScreen()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Supabase.instance.client.auth.signOut(),
                    icon: const FIcon(Icons.close),
                    label: Text(tr('Log out')),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _confirmDeleteAccount,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text(tr('Delete my account')),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FIcon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const FIcon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
