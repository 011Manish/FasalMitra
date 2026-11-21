import 'package:flutter/material.dart';
import '../models/catalog_product.dart';
import '../services/catalog_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _service = CatalogService();
  String? _category;
  late Future<List<CatalogProduct>> _future;

  static const _categories = ['seed', 'fertilizer', 'tool', 'irrigation'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = _service.fetchProducts(category: _category);

  Future<void> _enquire(CatalogProduct p) async {
    final ctrl = TextEditingController();
    final msg = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Enquire: ${p.name}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Your message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, ctrl.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (msg == null || msg.isEmpty) return;
    try {
      await _service.sendEnquiry(productId: p.id, message: msg);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Enquiry sent')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
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
                for (final c in [null, ..._categories])
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ChoiceChip(
                      label: Text(c ?? 'all'),
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
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return const Center(child: Text('No products yet'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final p = items[i];
                    return ListTile(
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.indicativePrice ?? '-'} ${p.currency} ${p.unit ?? ''}'
                        '${p.isDemo ? '  •  DEMO' : ''}\n'
                        '${p.sellerName ?? ''} ${p.sellerPhone ?? ''}',
                      ),
                      isThreeLine: true,
                      trailing: TextButton(
                        onPressed: () => _enquire(p),
                        child: const Text('Enquire'),
                      ),
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
