import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../services/link_launcher.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.sourceUri,
  });

  final String videoId;
  final String title;
  final Uri sourceUri;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final YoutubePlayerController _controller;
  late final StreamSubscription<YoutubePlayerValue> _sub;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
    _sub = _controller.listen((value) {
      if (value.error != YoutubeError.none && !_failed && mounted) {
        setState(() => _failed = true);
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _controller.close();
    super.dispose();
  }

  Future<void> _openOutside() async {
    final opened = await openExternally(widget.sourceUri);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the video link.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _failed
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'This video cannot be played inside the app.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _openOutside,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open in YouTube'),
                  ),
                ],
              ),
            )
          : Center(
              child: YoutubePlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
              ),
            ),
    );
  }
}
