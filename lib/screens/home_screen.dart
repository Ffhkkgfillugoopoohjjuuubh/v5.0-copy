import 'package:ai_tutor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_session.dart';
import '../models/project_model.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'news_screen.dart';
import 'settings_screen.dart';
import '../widgets/session_drawer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: SessionDrawer(
          onNewChat: () => _openNewChat(context, ref),
          onSelectSession: (session) => _openSession(context, session),
          onSelectProject: (project) => _openProjectChat(context, ref, project),
          onOpenSettings: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            );
          },
        ),
        appBar: AppBar(
          title: Text(l10n.appName),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(text: l10n.chatTab),
              Tab(text: l10n.newsTab),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _ChatLandingView(
              onPromptSelected: (prompt) => _openNewChat(
                context,
                ref,
                initialPrompt: prompt,
              ),
            ),
            const NewsScreen(),
          ],
        ),
      ),
    );
  }

  Future<void> _openNewChat(
    BuildContext context,
    WidgetRef ref, {
    String? initialPrompt,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final session = await ref.read(chatProvider.notifier).createSession(
          name: l10n.newChat,
        );
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          sessionId: session.id,
          initialPrompt: initialPrompt,
        ),
      ),
    );
  }

  Future<void> _openProjectChat(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
  ) async {
    final session = await ref.read(chatProvider.notifier).createSession(
          projectId: project.id,
          name: project.name,
        );
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(sessionId: session.id),
      ),
    );
  }

  Future<void> _openSession(BuildContext context, ChatSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(sessionId: session.id),
      ),
    );
  }
}

class _ChatLandingView extends StatelessWidget {
  const _ChatLandingView({
    required this.onPromptSelected,
  });

  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final suggestions = <String>[
      l10n.suggestionPhotosynthesis,
      l10n.suggestionMath,
      l10n.suggestionHistory,
      l10n.suggestionConcept,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[
                  Color(0xFF8B5CF6),
                  Color(0xFF6D4AE0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.welcomeTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.welcomeSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.startNewChat,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: suggestions
                .map(
                  (suggestion) => ActionChip(
                    label: Text(suggestion),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () => onPromptSelected(suggestion),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
