import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/support_contact.dart';
import '../services/link_launcher.dart';
import '../widgets/figma_icons.dart';

const _copiedMessage = 'Copied to clipboard.';
const _noAppMessage = 'No app found. Copied to clipboard.';

enum SupportKind { email, phone, whatsapp }

class SupportLink {
  const SupportLink({
    required this.kind,
    required this.value,
    required this.uri,
  });

  final SupportKind kind;
  final String value;
  final Uri uri;
}

String _digitsOnly(String text) => text.replaceAll(RegExp(r'\D'), '');

/// Turns the contact details into rows. Empty values are left out.
List<SupportLink> buildSupportLinks({
  required String email,
  required String phone,
  required String whatsapp,
}) {
  final links = <SupportLink>[];

  final emailValue = email.trim();
  if (emailValue.isNotEmpty) {
    links.add(SupportLink(
      kind: SupportKind.email,
      value: emailValue,
      // The subject is written by hand so the space stays %20 (not +).
      uri: Uri(
        scheme: 'mailto',
        path: emailValue,
        query: 'subject=FasalMitra%20support',
      ),
    ));
  }

  final phoneValue = phone.trim();
  if (_digitsOnly(phoneValue).isNotEmpty) {
    links.add(SupportLink(
      kind: SupportKind.phone,
      value: phoneValue,
      uri: Uri(
        scheme: 'tel',
        path: phoneValue.replaceAll(RegExp(r'[^0-9+]'), ''),
      ),
    ));
  }

  final whatsappValue = whatsapp.trim();
  final whatsappDigits = _digitsOnly(whatsappValue);
  if (whatsappDigits.isNotEmpty) {
    links.add(SupportLink(
      kind: SupportKind.whatsapp,
      value: whatsappValue,
      uri: Uri(scheme: 'https', host: 'wa.me', path: '/$whatsappDigits'),
    ));
  }

  return links;
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final links = buildSupportLinks(
      email: SupportContact.email,
      phone: SupportContact.phone,
      whatsapp: SupportContact.whatsapp,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: links.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Support contact details are not available yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Contact us for help with FasalMitra.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                for (final link in links) _SupportTile(link: link),
              ],
            ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.link});

  final SupportLink link;

  Future<void> _copy(BuildContext context, String message) async {
    await Clipboard.setData(ClipboardData(text: link.value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _open(BuildContext context) async {
    final opened = await openExternally(link.uri);
    if (opened || !context.mounted) return;
    await _copy(context, _noAppMessage);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (link.kind) {
      SupportKind.email => (Icons.email_outlined, 'Email'),
      SupportKind.phone => (Icons.phone_outlined, 'Phone'),
      SupportKind.whatsapp => (Icons.chat_outlined, 'WhatsApp'),
    };
    return Card(
      child: ListTile(
        leading: FIcon(icon),
        title: Text(label),
        subtitle: Text(link.value),
        onTap: () => _open(context),
        trailing: IconButton(
          icon: const FIcon(Icons.copy),
          tooltip: 'Copy',
          onPressed: () => _copy(context, _copiedMessage),
        ),
      ),
    );
  }
}
