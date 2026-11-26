import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_lang.dart';
import '../services/farm_service.dart';
import '../services/marketplace_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design_kit.dart';
import 'farms_list_screen.dart';
import 'home_grid_screen.dart';
import 'marketplace_screen.dart';
import 'notifications_screen.dart';
import 'profile_hub_screen.dart';
import '../widgets/figma_icons.dart';

/// App shell: top bar, the four tabs (Home, My Farms, Market, Profile) and the
/// bottom navigation bar from the design.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late final _farms = FarmService(Supabase.instance.client);
  late final _marketplace = MarketplaceService(Supabase.instance.client);

  void _goTo(int index) => setState(() => _tab = index);

  PreferredSizeWidget? _appBar() {
    switch (_tab) {
      case 0:
        return AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          leading: IconButton(
            tooltip: tr('Profile'),
            onPressed: () => _goTo(3),
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: FIcon(
                Icons.person_outline,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
          title: Row(
            children: [
              Image.asset('assets/images/logo.png', height: 26),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  'FasalMitra',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
            ],
          ),
          actions: const [
            NotificationBell(),
            LangToggle(),
            SizedBox(width: 12),
          ],
        );
      case 1:
        return AppBar(
          title: Text(
            tr('My Farms'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: const [LangToggle(), SizedBox(width: 12)],
        );
      default:
        // Market and Profile draw their own top bar.
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context) {
        final pages = <Widget>[
          HomeGridScreen(onOpenFarms: () => _goTo(1)),
          FarmsListScreen(service: _farms),
          MarketplaceScreen(service: _marketplace),
          ProfileHubScreen(farms: _farms, marketplace: _marketplace),
        ];
        return DesignBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _appBar(),
            body: pages[_tab],
            bottomNavigationBar: NavigationBar(
              backgroundColor: Colors.white,
              selectedIndex: _tab,
              onDestinationSelected: _goTo,
              destinations: [
                NavigationDestination(
                  icon: const FIcon(Icons.home_outlined),
                  selectedIcon: const FIcon(
                    Icons.home,
                    color: AppColors.primary,
                  ),
                  label: tr('Home'),
                ),
                NavigationDestination(
                  icon: const FIcon(Icons.grass),
                  selectedIcon: const FIcon(
                    Icons.grass,
                    color: AppColors.primary,
                  ),
                  label: tr('My Farms'),
                ),
                NavigationDestination(
                  icon: const FIcon(Icons.trending_up),
                  selectedIcon: const FIcon(
                    Icons.trending_up,
                    color: AppColors.primary,
                  ),
                  label: tr('Market'),
                ),
                NavigationDestination(
                  icon: const FIcon(Icons.person_outline),
                  selectedIcon: const FIcon(
                    Icons.person,
                    color: AppColors.primary,
                  ),
                  label: tr('Profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
