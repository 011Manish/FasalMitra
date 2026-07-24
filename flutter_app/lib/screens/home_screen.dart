import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/farm_service.dart';
import 'farms_list_screen.dart';
import 'reminders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late final _farms = FarmService(Supabase.instance.client);

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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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

  @override
  Widget build(BuildContext context) {
    final screens = [
      FarmsListScreen(service: _farms),
      RemindersScreen(service: _farms),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'My farms' : 'Reminders'),
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
              PopupMenuItem(value: 'delete', child: Text('Delete my account')),
            ],
          ),
        ],
      ),
      body: screens[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grass), label: 'Farms'),
          NavigationDestination(icon: Icon(Icons.notifications_active_outlined), label: 'Today'),
        ],
      ),
    );
  }
}
