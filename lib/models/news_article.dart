import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
  });

  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final DateTime publishedAt;

  factory NewsArticle.fromXml(XmlElement item) {
    final title = _findText(item, <String>['title']);
    final description = _stripHtml(
      _findText(item, <String>['description', 'encoded']),
    );
    final url = _findText(item, <String>['link']);
    final publishedRaw = _findText(item, <String>['pubDate', 'published']);
    final imageUrl = _findImage(item);

    return NewsArticle(
      title: title.isEmpty ? 'Untitled' : title,
      description: description,
      url: url,
      imageUrl: imageUrl,
      publishedAt: _parseDate(publishedRaw),
    );
  }

  static String _findText(XmlElement root, List<String> localNames) {
    for (final element in root.descendants.whereType<XmlElement>()) {
      if (localNames.contains(element.name.local)) {
        return element.innerText.trim();
      }
    }
    return '';
  }

  static String _findImage(XmlElement root) {
    for (final element in root.descendants.whereType<XmlElement>()) {
      final local = element.name.local;
      if (local == 'thumbnail' || local == 'content' || local == 'enclosure') {
        final url = element.getAttribute('url');
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    }
    return '';
  }

  static DateTime _parseDate(String raw) {
    if (raw.isEmpty) {
      return DateTime.now();
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return parsed.toLocal();
    }

    try {
      return DateFormat('EEE, dd MMM yyyy HH:mm:ss Z', 'en_US')
          .parseUtc(raw)
          .toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
