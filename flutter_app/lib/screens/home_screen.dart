import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/farm_service.dart';
import '../services/marketplace_service.dart';
import 'camera_choice_screen.dart';
import 'farms_list_screen.dart';
import 'marketplace_screen.dart';
import 'reminders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late final _farms = FarmService(Supabase.instance.client);
  late final _marketplace = MarketplaceService(Supabase.instance.client);

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account, all farm profiles, '
          'and all schedule items. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _farms.deleteAccount();
    }
  }

  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CameraChoiceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      FarmsListScreen(service: _farms),
      RemindersScreen(service: _farms),
      MarketplaceScreen(service: _marketplace),
    ];
    const titles = ['My farms', 'Reminders', 'Marketplace'];

    return Scaffold(
      appBar: _tab == 2
          ? null // MarketplaceScreen has its own AppBar (with the orders shortcut)
          : AppBar(
              title: Text(titles[_tab]),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'signout') {
                      await Supabase.instance.client.auth.signOut();
                    } else if (v == 'delete') {
                      await _confirmDeleteAccount();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'signout', child: Text('Sign out')),
                    PopupMenuItem(
                        value: 'delete', child: Text('Delete my account')),
                  ],
                ),
              ],
            ),
      body: screens[_tab],
      floatingActionButton: FloatingActionButton(
        heroTag: 'cameraButton',
        onPressed: _openCamera,
        tooltip: 'Camera',
        shape: const CircleBorder(),
        child: const Icon(Icons.photo_camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _NavTab(
                  icon: Icons.grass,
                  label: 'Farms',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
              ),
              // Gap where the docked camera FAB sits.
              const SizedBox(width: 72),
              Expanded(
                child: _NavTab(
                  icon: Icons.notifications_active_outlined,
                  label: 'Today',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ),
              Expanded(
                child: _NavTab(
                  icon: Icons.storefront_outlined,
                  label: 'Market',
                  selected: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
