import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/news_article.dart';

class NewsService {
  NewsService({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _cacheDuration = Duration(minutes: 15);
  static const Map<String, String> _feeds = <String, String>{
    'india': 'https://timesofindia.indiatimes.com/rssfeeds/296589292.cms',
    'technology': 'https://feeds.feedburner.com/gadgets360-latest',
    'education': 'https://www.thehindu.com/education/feeder/default.rss',
    'science': 'https://www.thehindu.com/sci-tech/feeder/default.rss',
  };

  final http.Client _client;
  final Map<String, _CachedArticles> _cache = <String, _CachedArticles>{};

  Future<List<NewsArticle>> fetchArticles(
    String category, {
    bool forceRefresh = false,
  }) async {
    final normalizedCategory = category.toLowerCase();
    final cached = _cache[normalizedCategory];

    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) < _cacheDuration) {
      return cached.articles;
    }

    final url = _feeds[normalizedCategory] ?? _feeds['india']!;
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to fetch news right now.');
    }

    final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
    final articles = document
        .findAllElements('item')
        .map(NewsArticle.fromXml)
        .where((article) => article.url.isNotEmpty)
        .toList();

    _cache[normalizedCategory] = _CachedArticles(
      articles: articles,
      cachedAt: DateTime.now(),
    );

    return articles;
  }
}

class _CachedArticles {
  const _CachedArticles({
    required this.articles,
    required this.cachedAt,
  });

  final List<NewsArticle> articles;
  final DateTime cachedAt;
}
