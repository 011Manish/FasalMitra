import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalog_product.dart';
import '../models/learning_content.dart';
import '../services/home_content_service.dart';
import '../services/link_launcher.dart';
import 'crop_guide_screen.dart';
import 'learning_academy_screen.dart';
import 'market_prices_screen.dart';
import 'price_prediction_screen.dart';
import 'shop_screen.dart';

const _tutorialsError =
    'Could not load tutorials. Check your internet and try again.';
const _productError =
    'Could not load products. Check your internet and try again.';

class HomeGridScreen extends StatefulWidget {
  const HomeGridScreen({super.key});

  @override
  State<HomeGridScreen> createState() => _HomeGridScreenState();
}

class _HomeGridScreenState extends State<HomeGridScreen> {
  late final _content = HomeContentService(Supabase.instance.client);
  late final Future<String?> _firstName = _content.firstName();
  late Future<LearningContent?> _video = _content.featuredVideo();
  late Future<CatalogProduct?> _product = _content.featuredProduct();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<String?>(
          future: _firstName,
          builder: (context, snap) {
            // A missing name is not worth an error message: greet without it.
            final name = snap.data;
            return Text(
              name == null ? 'Hello' : 'Hello, $name',
              style: Theme.of(context).textTheme.headlineSmall,
            );
          },
        ),
        const SizedBox(height: 16),
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
          onRetry: () => setState(() => _product = _content.featuredProduct()),
          builder: (product) => _ProductCard(product: product),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _HomeTile(
              icon: Icons.ondemand_video_outlined,
              label: 'Tutorials',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VideoTutorialsScreen(),
                ),
              ),
            ),
            _HomeTile(
              icon: Icons.bar_chart_outlined,
              label: 'Market Prices',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MarketPricesScreen(),
                ),
              ),
            ),
            _HomeTile(
              icon: Icons.trending_up_outlined,
              label: 'Price Prediction',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PricePredictionScreen(),
                ),
              ),
            ),
            _HomeTile(
              icon: Icons.storefront_outlined,
              label: 'Shop',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ShopScreen(),
                ),
              ),
            ),
            _HomeTile(
              icon: Icons.eco_outlined,
              label: 'Crop Guide',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CropGuideScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
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
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) {
              return _MessageCard(
                child: Column(
                  children: [
                    Text(errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                        onPressed: onRetry, child: const Text('Retry')),
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
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VideoTutorialsScreen()),
        ),
        child: Row(
          children: [
            _Thumbnail(
                url: _thumbnail, fallbackIcon: Icons.ondemand_video_outlined),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(video.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall),
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
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ShopScreen()),
        ),
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
                    Text(product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall),
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
      child: Icon(fallbackIcon),
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
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 42,
                color: scheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
