import 'package:url_launcher/url_launcher.dart';

final _youtubeIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Returns [raw] as a Uri only when it is a valid https URL.
Uri? parseHttpsUrl(String? raw) {
  final uri = Uri.tryParse(raw?.trim() ?? '');
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}

/// Opens [uri] in another app. Returns false when nothing can handle it.
Future<bool> openExternally(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Returns the YouTube video id of [uri], or null if it is not a YouTube video link.
String? youtubeVideoId(Uri uri) {
  final host = uri.host.toLowerCase();
  String? id;
  if (host == 'youtu.be') {
    id = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  } else if (host == 'youtube.com' ||
      host == 'www.youtube.com' ||
      host == 'm.youtube.com') {
    if (uri.path == '/watch') {
      id = uri.queryParameters['v'];
    } else if (uri.pathSegments.length >= 2 &&
        (uri.pathSegments.first == 'embed' ||
            uri.pathSegments.first == 'shorts')) {
      id = uri.pathSegments[1];
    }
  }
  return id != null && _youtubeIdPattern.hasMatch(id) ? id : null;
}

/// Returns YouTube's own thumbnail link for a YouTube video link, else null.
String? youtubeThumbnailUrl(String? raw) {
  final uri = parseHttpsUrl(raw);
  final id = uri == null ? null : youtubeVideoId(uri);
  return id == null ? null : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}
