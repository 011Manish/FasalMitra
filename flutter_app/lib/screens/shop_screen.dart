import 'package:flutter/material.dart';

import '../models/catalog_product.dart';
import '../services/catalog_service.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _service = CatalogService();
  String? _category;
  late Future<List<CatalogProduct>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = _service.fetchProducts(category: _category);

  void _openDetail(CatalogProduct p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: p, service: _service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final c in [null, ...catalogCategoryLabels.keys])
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ChoiceChip(
                      label: Text(
                        c == null ? 'All' : catalogCategoryLabels[c] ?? c,
                      ),
                      selected: _category == c,
                      onSelected: (_) => setState(() {
                        _category = c;
                        _load();
                      }),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CatalogProduct>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _LoadError(onRetry: () => setState(_load));
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('No products yet'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final p = items[i];
                    return ListTile(
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ProductImage(url: p.imageUrl),
                        ),
                      ),
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.indicativePrice ?? '-'} ${p.currency} ${p.unit ?? ''}'
                        '${p.isDemo ? '  \u2022  DEMO' : ''}\n'
                        '${p.sellerName ?? ''} ${p.sellerPhone ?? ''}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openDetail(p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load. Check your internet.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
