import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/learning_content.dart';
import '../services/learning_service.dart';

class LearningAcademyScreen extends StatelessWidget {
  const LearningAcademyScreen({super.key});

  static const _categories = [
    ('course', 'Courses', Icons.menu_book_outlined),
    ('video', 'Videos', Icons.play_circle_outline),
    ('ebook', 'E-books', Icons.import_contacts_outlined),
    ('success_story', 'Success Stories', Icons.emoji_events_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Academy')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final (type, label, icon) in _categories)
            _CategoryTile(
              icon: icon,
              label: label,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      _CategoryListScreen(contentType: type, label: label),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: scheme.primary),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _CategoryListScreen extends StatefulWidget {
  const _CategoryListScreen({required this.contentType, required this.label});
  final String contentType;
  final String label;

  @override
  State<_CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<_CategoryListScreen> {
  late final _service = LearningService(Supabase.instance.client);
  late Future<List<LearningContent>> _load;

  @override
  void initState() {
    super.initState();
    _load = _service.listContent(contentType: widget.contentType);
  }

  Future<void> _refresh() async {
    setState(
        () => _load = _service.listContent(contentType: widget.contentType));
    await _load;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.label)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<LearningContent>>(
          future: _load,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load: ${snap.error}'),
                )
              ]);
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('Nothing here yet.')),
              ]);
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final it = items[i];
                return ListTile(
                  title: Text(it.title),
                  subtitle: Text(it.summary),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => _ContentDetailScreen(item: it)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ContentDetailScreen extends StatelessWidget {
  const _ContentDetailScreen({required this.item});
  final LearningContent item;

  Future<void> _openLink(BuildContext context) async {
    final url = item.externalUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.body.isNotEmpty)
              Text(item.body, style: Theme.of(context).textTheme.bodyLarge),
            if (item.externalUrl != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openLink(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open link'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
