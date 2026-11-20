import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/consultation_message.dart';
import '../services/consultation_service.dart';
import '../services/photo_service.dart';

class ConsultationChatScreen extends StatefulWidget {
  const ConsultationChatScreen({
    super.key,
    required this.appointmentId,
    required this.expertName,
  });

  final String appointmentId;
  final String expertName;

  @override
  State<ConsultationChatScreen> createState() => _ConsultationChatScreenState();
}

class _ConsultationChatScreenState extends State<ConsultationChatScreen> {
  late final _service = ConsultationService(Supabase.instance.client);
  final _input = TextEditingController();
  late Future<List<ConsultationMessage>> _load;
  bool _sending = false;
  bool _attaching = false;

  @override
  void initState() {
    super.initState();
    _load = _service.listMessages(widget.appointmentId);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _load = _service.listMessages(widget.appointmentId));
    await _load;
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.sendMessage(
          appointmentId: widget.appointmentId, body: text);
      _input.clear();
      await _refresh();
    } catch (e) {
      _snack('Send failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _attach() async {
    setState(() => _attaching = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
      );
      if (picked == null || picked.files.single.path == null) return;
      await _service.uploadDocument(
        appointmentId: widget.appointmentId,
        file: File(picked.files.single.path!),
      );
      await _refresh();
    } on PhotoTooLarge catch (e) {
      _snack(e.toString());
    } catch (e) {
      _snack('Attach failed: $e');
    } finally {
      if (mounted) setState(() => _attaching = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final me = Supabase.instance.client.auth.currentUser!.id;
    final tf = DateFormat.jm();

    return Scaffold(
      appBar: AppBar(title: Text(widget.expertName)),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<ConsultationMessage>>(
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
                  final msgs = snap.data ?? [];
                  if (msgs.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 120),
                      Center(
                          child: Text('Say hello to start the conversation.')),
                    ]);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) => _Bubble(
                      msg: msgs[i],
                      mine: msgs[i].senderId == me,
                      time: tf.format(msgs[i].createdAt.toLocal()),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: _attaching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.attach_file),
                    tooltip: 'Attach document',
                    onPressed: _attaching ? null : _attach,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, required this.mine, required this.time});
  final ConsultationMessage msg;
  final bool mine;
  final String time;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDoc = msg.body.startsWith('[document] ');
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color:
              mine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDoc)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description_outlined, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                      child: Text(msg.body.substring('[document] '.length))),
                ],
              )
            else
              Text(msg.body),
            const SizedBox(height: 2),
            Text(time, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
