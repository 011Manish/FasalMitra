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
  String? _category; // null = all
  String? _language; // null = all

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<LearningContent>> _fetch() => _service.listContent(
        contentType: widget.contentType,
        category: _category,
        language: _language,
      );

  Future<void> _refresh() async {
    setState(() => _load = _fetch());
    await _load;
  }

  void _pickCategory(String? value) {
    setState(() {
      _category = value;
      _load = _fetch();
    });
  }

  void _pickLanguage(String? value) {
    setState(() {
      _language = value;
      _load = _fetch();
    });
  }

  Widget _chipRow({
    required Map<String, String> options,
    required String? selected,
    required void Function(String?) onPick,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onPick(null),
            ),
          ),
          for (final e in options.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(e.value),
                selected: selected == e.key,
                onSelected: (_) => onPick(e.key),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.label)),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _chipRow(
            options: learningCategoryLabels,
            selected: _category,
            onPick: _pickCategory,
          ),
          _chipRow(
            options: learningLanguageLabels,
            selected: _language,
            onPick: _pickLanguage,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LanguageBadge(code: it.language),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
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
          ),
        ],
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        learningLanguageLabels[code] ?? code.toUpperCase(),
        style: TextStyle(fontSize: 12, color: scheme.onSecondaryContainer),
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
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(
                    learningCategoryLabels[item.category] ?? item.category,
                  ),
                ),
                _LanguageBadge(code: item.language),
              ],
            ),
            const SizedBox(height: 12),
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
