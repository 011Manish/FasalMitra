import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/plant_scan.dart';

// Flip this to false to hide the "More inquiry" button everywhere. The
// core photo-to-report flow works fully with this off.
const bool enableFollowUpChat = true;

class PlantScanFollowUpChatScreen extends StatefulWidget {
  const PlantScanFollowUpChatScreen({super.key, required this.scan});
  final PlantScan scan;

  @override
  State<PlantScanFollowUpChatScreen> createState() =>
      _PlantScanFollowUpChatScreenState();
}

class _ChatMessage {
  _ChatMessage(this.text, {required this.fromUser});
  final String text;
  final bool fromUser;
}

class _PlantScanFollowUpChatScreenState
    extends State<PlantScanFollowUpChatScreen> {
  final _controller = TextEditingController();
  final _messages = <_ChatMessage>[];
  bool _sending = false;

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(question, fromUser: true));
      _controller.clear();
      _sending = true;
    });

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'plant-scan-followup',
        body: {'scan_id': widget.scan.id, 'question': question},
      );
      final answer = res.status == 200
          ? (res.data['answer']?.toString() ?? 'No answer returned.')
          : 'Something went wrong answering that — try again.';
      setState(() => _messages.add(_ChatMessage(answer, fromUser: false)));
    } catch (e) {
      setState(() => _messages
          .add(_ChatMessage('Something went wrong: $e', fromUser: false)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask about this scan')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment:
                      m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: m.fromUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'e.g. is this safe for nearby plants?',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
