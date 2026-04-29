import 'package:ai_tutor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_session.dart';
import '../models/project_model.dart';
import '../providers/chat_provider.dart';
import '../widgets/session_drawer.dart';
import 'chat_screen.dart';
import 'news_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
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
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _openNewChat(context, ref),
              child: const Icon(Icons.add_comment_outlined),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l10n.chatTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.newspaper_outlined),
            selectedIcon: const Icon(Icons.newspaper_rounded),
            label: l10n.newsTab,
          ),
        ],
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
      l10n.suggestionGravity,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 28),
          Text(
            l10n.greeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.greetingSubtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: suggestions
                .map(
                  (suggestion) => ActionChip(
                    avatar: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(suggestion),
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
