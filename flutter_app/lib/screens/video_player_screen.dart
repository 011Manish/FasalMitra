import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../l10n/app_lang.dart';
import '../services/link_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/design_kit.dart';
import '../widgets/figma_icons.dart';

/// Tutorial Player screen from the Figma design: back + language switch,
/// rounded video with a big play button, progress bar with times, then the
/// title, a language tag and the description.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.sourceUri,
    this.languageLabel,
    this.description,
  });

  final String videoId;
  final String title;
  final Uri sourceUri;

  /// e.g. "Nepali". Shown as the small green tag under the title.
  final String? languageLabel;
  final String? description;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final YoutubePlayerController _controller;
  late final StreamSubscription<YoutubePlayerValue> _sub;
  late final StreamSubscription<YoutubeVideoState> _timeSub;
  bool _failed = false;
  bool _playing = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
      ),
    );
    _sub = _controller.listen((value) {
      if (!mounted) return;
      if (value.error != YoutubeError.none && !_failed) {
        setState(() => _failed = true);
        return;
      }
      final playing = value.playerState == PlayerState.playing ||
          value.playerState == PlayerState.buffering;
      final duration = value.metaData.duration;
      if (playing != _playing || duration != _duration) {
        setState(() {
          _playing = playing;
          _duration = duration;
        });
      }
    });
    _timeSub = _controller.videoStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _position = state.position);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _timeSub.cancel();
    _controller.close();
    super.dispose();
  }

  Future<void> _openOutside() async {
    final opened = await openExternally(widget.sourceUri);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Could not open the video link.'))),
    );
  }

  void _togglePlay() {
    if (_playing) {
      _controller.pauseVideo();
    } else {
      _controller.playVideo();
    }
  }

  void _seekToFraction(double f) {
    if (_duration.inSeconds <= 0) return;
    final target = _duration.inSeconds * f.clamp(0.0, 1.0);
    _controller.seekTo(seconds: target, allowSeekAhead: true);
    setState(() => _position = Duration(seconds: target.round()));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Widget _video() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: const Color(0xFF111611),
          child: _failed
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr('This video cannot be played inside the app.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _openOutside,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          icon: const FIcon.named('play', size: 18),
                          label: Text(tr('Open in YouTube')),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    IgnorePointer(
                      child: YoutubePlayer(
                        controller: _controller,
                        aspectRatio: 16 / 9,
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _togglePlay,
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _playing ? 0 : 1,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            child: const Center(
                              child: FIcon.named(
                                'play',
                                size: 28,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _progress() {
    final total = _duration.inMilliseconds;
    final fraction =
        total <= 0 ? 0.0 : (_position.inMilliseconds / total).clamp(0.0, 1.0);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, box) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _seekToFraction(d.localPosition.dx / box.maxWidth),
            onHorizontalDragUpdate: (d) =>
                _seekToFraction(d.localPosition.dx / box.maxWidth),
            child: SizedBox(
              height: 22,
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.mutedText.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: fraction,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmt(_position), style: _timeStyle),
            Text(_fmt(_duration), style: _timeStyle),
          ],
        ),
      ],
    );
  }

  static const _timeStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xFF2F6636),
  );

  @override
  Widget build(BuildContext context) {
    final description = widget.description?.trim() ?? '';
    return LangBuilder(
      builder: (context) => DesignBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      _video(),
                      const SizedBox(height: 10),
                      _progress(),
                      const SizedBox(height: 12),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      if (widget.languageLabel != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.languageLabel!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2F6636),
                            ),
                          ),
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: Color(0xFF2F6636),
                          ),
                        ),
                      ],
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
