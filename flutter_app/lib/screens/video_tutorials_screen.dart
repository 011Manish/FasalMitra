import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_lang.dart';
import '../models/learning_content.dart';
import '../services/learning_service.dart';
import '../services/link_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/design_kit.dart';
import '../widgets/figma_icons.dart';
import 'video_player_screen.dart';

const _tabs = <(String, String)>[
  ('en', 'English'),
  ('hi', 'हिन्दी'),
  ('ne', 'नेपाली'),
];

const _darkGreen = Color(0xFF2F6636);

/// Tutorials screen from the Figma design: back + language switch, title,
/// English / Hindi / Nepali tabs and a list of video rows. Tapping a row
/// opens the Tutorial Player screen.
class VideoTutorialsScreen extends StatefulWidget {
  const VideoTutorialsScreen({super.key});

  @override
  State<VideoTutorialsScreen> createState() => _VideoTutorialsScreenState();
}

class _VideoTutorialsScreenState extends State<VideoTutorialsScreen> {
  late final _service = LearningService(Supabase.instance.client);
  late Future<List<LearningContent>> _load = _fetch();
  late String _lang = AppLang.isNepali ? 'ne' : 'en';

  Future<List<LearningContent>> _fetch() =>
      _service.listContent(contentType: videoContentType);

  Future<void> _refresh() async {
    setState(() => _load = _fetch());
    try {
      await _load;
    } catch (_) {
      // The error card shows the problem.
    }
  }

  String _label(String code) =>
      _tabs.firstWhere((t) => t.$1 == code, orElse: () => (code, code)).$2;

  Future<void> _open(LearningContent item) async {
    final uri = parseHttpsUrl(item.externalUrl);
    if (uri == null) {
      _snack(tr('This video has no link yet.'));
      return;
    }
    final videoId = youtubeVideoId(uri);
    if (videoId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            videoId: videoId,
            title: item.title,
            sourceUri: uri,
            languageLabel: _label(item.language),
            description: item.summary.isNotEmpty ? item.summary : item.body,
          ),
        ),
      );
      return;
    }
    final opened = await openExternally(uri);
    if (!mounted || opened) return;
    _snack(tr('Could not open the video link.'));
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _tabBar() {
    Widget tab((String, String) t) {
      final on = _lang == t.$1;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _lang = t.$1),
          child: Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              t.$2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.mutedText.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.mutedText, width: 1.5),
      ),
      child: Row(children: [for (final t in _tabs) tab(t)]),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const FIcon.named('book', size: 44, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            tr('No tutorials yet'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            tr('Videos will appear here when they are added.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.border),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            tr('Could not load tutorials. Check your internet and try again.'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _refresh,
            child: Text(tr('Retry')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context) => DesignBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    children: [
                      Row(
                        children: [
                          BackPill(
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          const LangToggle(),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        tr('Tutorials'),
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('Short videos in English, Hindi and Nepali.'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.border,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _tabBar(),
                      const SizedBox(height: 12),
                      FutureBuilder<List<LearningContent>>(
                        future: _load,
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 48),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (snap.hasError) return _errorCard();
                          final items = (snap.data ?? [])
                              .where((i) => i.language == _lang)
                              .toList();
                          if (items.isEmpty) return _emptyCard();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 2, bottom: 8),
                                child: Text(
                                  AppLang.isNepali
                                      ? '${tr('Videos in')} ${_label(_lang)}'
                                      : 'Videos in ${_label(_lang)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              for (final it in items)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _VideoRow(
                                    item: it,
                                    onTap: () => _open(it),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({required this.item, required this.onTap});
  final LearningContent item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = parseHttpsUrl(
      item.thumbnailUrl ?? youtubeThumbnailUrl(item.externalUrl),
    );
    final category = learningCategoryLabels[item.category];
    final playIcon = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: thumb == null ? Colors.transparent : Colors.white70,
      ),
      child: const Center(
        child: FIcon.named('play', size: 20, color: AppColors.primary),
      ),
    );
    return Material(
      color: Colors.white.withOpacity(0.62),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 84,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: AppColors.primary.withOpacity(0.2)),
                      if (thumb != null)
                        Image.network(
                          thumb.toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      Center(child: playIcon),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    if (category != null)
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _darkGreen,
                        ),
                      ),
                  ],
                ),
              ),
              const FIcon.named('chevR', size: 18, color: Color(0xFF4A4E4A)),
            ],
          ),
        ),
      ),
    );
  }
}
