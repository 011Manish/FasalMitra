import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_lang.dart';
import '../models/app_notification.dart';
import '../models/catalog_product.dart';
import '../models/farm_profile.dart';
import '../models/learning_content.dart';
import '../services/farm_service.dart';
import '../services/home_content_service.dart';
import '../services/link_launcher.dart';
import '../services/marketplace_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design_kit.dart';
import 'camera_choice_screen.dart';
import 'create_listing_screen.dart';
import 'crop_guide_screen.dart';
import 'farm_edit_screen.dart';
import 'video_tutorials_screen.dart';
import 'market_prices_screen.dart';
import 'price_prediction_screen.dart';
import 'shop_screen.dart';
import '../widgets/figma_icons.dart';

const _tutorialsError =
    'Could not load tutorials. Check your internet and try again.';
const _productError =
    'Could not load products. Check your internet and try again.';

class HomeGridScreen extends StatefulWidget {
  const HomeGridScreen({super.key, this.onOpenFarms});

  /// Switches the app to the My Farms tab.
  final VoidCallback? onOpenFarms;

  @override
  State<HomeGridScreen> createState() => _HomeGridScreenState();
}

class _HomeGridScreenState extends State<HomeGridScreen> {
  late final _sb = Supabase.instance.client;
  late final _content = HomeContentService(_sb);
  late final _farmService = FarmService(_sb);
  late final _marketplace = MarketplaceService(_sb);
  late final Future<String?> _firstName = _content.firstName();
  late final Stream<List<AppNotification>> _notes = NotificationService(_sb)
      .watch();
  late Future<LearningContent?> _video = _content.featuredVideo();
  late Future<CatalogProduct?> _product = _content.featuredProduct();
  late Future<List<FarmProfile>> _farms = _farmService.listMine();

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addFarm() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FarmEditScreen(service: _farmService)),
    );
    if (changed == true && mounted) {
      setState(() => _farms = _farmService.listMine());
    }
  }

  Future<void> _sellProduce() async {
    String? role;
    try {
      role = await _marketplace.myRole();
    } catch (_) {
      // The server checks the role again when the listing is saved.
    }
    if (!mounted) return;
    if (role != null && role != 'farmer' && role != 'admin') {
      _snack(farmerOnlyMessage);
      return;
    }
    _open(CreateListingScreen(service: _marketplace));
  }

  String _totalArea(List<FarmProfile> farms) {
    final totals = <String, double>{};
    for (final f in farms) {
      final unit = f.landSizeValue == null ? 'hectare' : f.landUnit;
      totals[unit] =
          (totals[unit] ?? 0) + (f.landSizeValue ?? f.landSizeHectares);
    }
    return totals.entries
        .map((e) {
          final v = e.value;
          final text = v == v.roundToDouble()
              ? v.toInt().toString()
              : v.toStringAsFixed(2);
          return '$text ${e.key}';
        })
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context) {
        final theme = Theme.of(context);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                FutureBuilder<String?>(
                  future: _firstName,
                  builder: (context, snap) {
                    // A missing name is not worth an error message: greet without it.
                    final name = snap.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('Namaste,'), style: theme.textTheme.bodyMedium),
                        if (name != null)
                          Text(
                            name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _farmOverview(theme),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _HomeTile(
                      icon: Icons.grass,
                      label: tr('My Farms'),
                      onTap: () => widget.onOpenFarms?.call(),
                    ),
                    _HomeTile(
                      icon: Icons.center_focus_strong_outlined,
                      label: tr('AI Crop Scan'),
                      onTap: () =>
                          Navigator.of(context).push(CameraChoiceScreen.route()),
                    ),
                    _HomeTile(
                      icon: Icons.trending_up,
                      label: tr('Market Prices'),
                      onTap: () => _open(const MarketPricesScreen()),
                    ),
                    _HomeTile(
                      icon: Icons.inventory_2_outlined,
                      label: tr('Sell Produce'),
                      onTap: _sellProduce,
                    ),
                    _HomeTile(
                      icon: Icons.shopping_bag_outlined,
                      label: tr('Agricultural Shop'),
                      onTap: () => _open(const ShopScreen()),
                    ),
                    _HomeTile(
                      icon: Icons.menu_book_outlined,
                      label: tr('Tutorials'),
                      onTap: () => _open(const VideoTutorialsScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _recentActivity(theme),
                const SizedBox(height: 12),
                _farmingInformation(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _farmOverview(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<FarmProfile>>(
          future: _farms,
          builder: (context, snap) {
            Widget title([Widget? trailing]) => Row(
              children: [
                Expanded(
                  child: Text(
                    tr('Farm overview'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            );

            if (snap.connectionState != ConnectionState.done) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title(),
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snap.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title(),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      tr('Could not load farms. Check your internet.'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: FilledButton.tonal(
                      onPressed: () =>
                          setState(() => _farms = _farmService.listMine()),
                      child: Text(tr('Retry')),
                    ),
                  ),
                ],
              );
            }
            final farms = snap.data ?? [];
            if (farms.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title(),
                  const SizedBox(height: 12),
                  Center(child: Text(tr('No farms added yet.'))),
                  const SizedBox(height: 12),
                  Center(
                    child: FilledButton(
                      onPressed: _addFarm,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: Text(tr('Add your first farm')),
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title(
                  TextButton(
                    onPressed: () => widget.onOpenFarms?.call(),
                    style: TextButton.styleFrom(foregroundColor: Colors.black),
                    child: Text(
                      tr('View farms'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: tr('Farms'),
                        value: '${farms.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Stat(
                        label: tr('Total area'),
                        value: _totalArea(farms),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _recentActivity(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Recent activity'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<AppNotification>>(
              stream: _notes,
              builder: (context, snap) {
                final items = (snap.data ?? const <AppNotification>[])
                    .take(3)
                    .toList();
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(tr('No recent activity.')),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final n in items)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: FIcon(
                          n.isRead
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _farmingInformation(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Farming information'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _FeaturedBlock<LearningContent>(
              title: 'Featured tutorial',
              future: _video,
              errorMessage: _tutorialsError,
              emptyMessage: 'No tutorials yet.',
              onRetry: () => setState(() => _video = _content.featuredVideo()),
              builder: (video) => _VideoCard(video: video),
            ),
            _FeaturedBlock<CatalogProduct>(
              title: 'Featured product',
              future: _product,
              errorMessage: _productError,
              emptyMessage: 'No products yet.',
              onRetry: () =>
                  setState(() => _product = _content.featuredProduct()),
              builder: (product) => _ProductCard(product: product),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const FIcon(Icons.eco_outlined, color: AppColors.primary),
              title: Text(tr('Crop Guide')),
              trailing: const FIcon(Icons.chevron_right),
              onTap: () => _open(const CropGuideScreen()),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const FIcon(
                Icons.trending_up_outlined,
                color: AppColors.primary,
              ),
              title: Text(tr('Price Prediction')),
              trailing: const FIcon(Icons.chevron_right),
              onTap: () => _open(const PricePredictionScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.circle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedBlock<T> extends StatelessWidget {
  const _FeaturedBlock({
    required this.title,
    required this.future,
    required this.errorMessage,
    required this.emptyMessage,
    required this.onRetry,
    required this.builder,
  });

  final String title;
  final Future<T?> future;
  final String errorMessage;
  final String emptyMessage;
  final VoidCallback onRetry;
  final Widget Function(T item) builder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FutureBuilder<T?>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _MessageCard(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return _MessageCard(
                child: Column(
                  children: [
                    Text(errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final item = snap.data;
            if (item == null) {
              return _MessageCard(child: Center(child: Text(emptyMessage)));
            }
            return builder(item);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: double.infinity,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});
  final LearningContent video;

  String? get _thumbnail =>
      parseHttpsUrl(video.thumbnailUrl)?.toString() ??
      youtubeThumbnailUrl(video.externalUrl);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const VideoTutorialsScreen())),
        child: Row(
          children: [
            _Thumbnail(
              url: _thumbnail,
              fallbackIcon: Icons.ondemand_video_outlined,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final CatalogProduct product;

  String get _priceLine {
    final price = product.indicativePrice;
    if (price == null) return 'Price not listed';
    final unit = product.unit;
    final perUnit = (unit == null || unit.isEmpty) ? '' : ' / $unit';
    return '${product.currency} ${price.toStringAsFixed(2)}$perUnit';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ShopScreen())),
        child: Row(
          children: [
            _Thumbnail(
              url: parseHttpsUrl(product.imageUrl)?.toString(),
              fallbackIcon: Icons.inventory_2_outlined,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(_priceLine, style: theme.textTheme.bodyMedium),
                    if (product.isDemo)
                      Text('Sample product', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.fallbackIcon});
  final String? url;
  final IconData fallbackIcon;

  static const _size = 96.0;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: FIcon(fallbackIcon),
    );
    final u = url;
    if (u == null) return fallback;
    return Image.network(
      u,
      width: _size,
      height: _size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FIcon(icon, size: 30, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
