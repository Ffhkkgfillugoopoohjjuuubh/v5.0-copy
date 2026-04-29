import 'package:ai_tutor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/news_article.dart';
import '../services/news_service.dart';

final newsProvider = StateNotifierProvider<NewsNotifier, NewsState>(
  (ref) => NewsNotifier(NewsService())..load(),
);

class NewsState {
  const NewsState({
    required this.category,
    required this.articles,
  });

  final String category;
  final AsyncValue<List<NewsArticle>> articles;

  NewsState copyWith({
    String? category,
    AsyncValue<List<NewsArticle>>? articles,
  }) {
    return NewsState(
      category: category ?? this.category,
      articles: articles ?? this.articles,
    );
  }
}

class NewsNotifier extends StateNotifier<NewsState> {
  NewsNotifier(this._newsService)
      : super(
          const NewsState(
            category: 'india',
            articles: AsyncValue<List<NewsArticle>>.loading(),
          ),
        );

  final NewsService _newsService;

  Future<void> load({
    String? category,
    bool forceRefresh = false,
  }) async {
    final nextCategory = category ?? state.category;
    state = state.copyWith(
      category: nextCategory,
      articles: const AsyncValue<List<NewsArticle>>.loading(),
    );

    try {
      final articles = await _newsService.fetchArticles(
        nextCategory,
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(articles: AsyncValue.data(articles));
    } catch (error, stackTrace) {
      state = state.copyWith(
        articles: AsyncValue<List<NewsArticle>>.error(error, stackTrace),
      );
    }
  }
}

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(newsProvider);
    final notifier = ref.read(newsProvider.notifier);

    final categories = <String, String>{
      'india': l10n.india,
      'technology': l10n.technology,
      'education': l10n.education,
      'science': l10n.science,
    };

    return Column(
      children: <Widget>[
        SizedBox(
          height: 58,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: categories.entries.map((entry) {
              final selected = state.category == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) => notifier.load(category: entry.key),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: state.articles.when(
            data: (articles) {
              if (articles.isEmpty) {
                return Center(child: Text(l10n.noNewsAvailable));
              }

              return RefreshIndicator(
                onRefresh: () => notifier.load(
                  category: state.category,
                  forceRefresh: true,
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openUrl(context, article.url, l10n),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                article.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                article.description.isEmpty
                                    ? l10n.noDescriptionAvailable
                                    : article.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _timeAgo(l10n, article.publishedAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            error: (_, stackTrace) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(l10n.noNewsAvailable),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => notifier.load(
                        category: state.category,
                        forceRefresh: true,
                      ),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            },
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (context, index) => const _NewsSkeleton(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(
    BuildContext context,
    String url,
    AppLocalizations l10n,
  ) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToOpenLink)),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToOpenLink)),
      );
    }
  }

  String _timeAgo(AppLocalizations l10n, DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    }
    if (difference.inHours < 1) {
      return l10n.minutesAgo(difference.inMinutes);
    }
    if (difference.inDays < 1) {
      return l10n.hoursAgo(difference.inHours);
    }
    return l10n.daysAgo(difference.inDays);
  }
}

class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget bar(double width, double height) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          bar(double.infinity, 18),
          const SizedBox(height: 10),
          bar(double.infinity, 12),
          const SizedBox(height: 8),
          bar(MediaQuery.sizeOf(context).width * 0.62, 12),
          const SizedBox(height: 12),
          bar(90, 10),
        ],
      )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.22)),
    );
  }
}
